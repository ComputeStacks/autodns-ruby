module AutoDNS::Dns
  # =DNS Zone for AutoDNS
  #
  # Attributes:
  # [+id+]
  # [+name+]
  # [+records+] An Array of AutoDNS::Dns::ZoneRecord
  # [+dnssec+] Boolean if DNSSEC is enabled. (Disabled in AutoDNS)
  # [+features+] Hash of parameters specific to this DNS provider
  # [+soa_email+] Public email in the SOA record for this zone.
  # [+axfr_ips+] An Array of IPs allowed to AXFR this zone.
  # [+errors+] An Array of Strings
  # [+updated_at+]
  # [+created_at+]
  #
  class Zone

    attr_accessor :id,
                  :name,
                  :records,
                  :dnssec,
                  :account_id,
                  :features,
                  :soa_email,
                  :axfr_ips,
                  :errors,
                  :updated_at,
                  :created_at

    # Requires AutoDNS::Client, and the ID of the zone (nil for new zones).
    def initialize(client, id, data = {})
      @client = client
      self.id = id
      self.name = id
      self.dnssec = false # not implemented
      self.records = default_records
      self.features = {}
      self.axfr_ips = []
      self.errors = []
      self.soa_email = AutoDNS.config[:soa_email]
      load!(data) unless data.empty?
    end

    # Load Zone
    # Get Zone Info (0205) pg.179
    def load!(data)
      return false if self.id.nil?
      self.features = {
          ns_action: data['ns_action'],
          owner: data['owner']['user'],
          updated_by: data['updated_by']['user'],
          comment: data['comment'],
          primary_ns: data['system_ns']
      }
      self.records = process_records!(data)
      self.axfr_ips = data['allow_transfer_from'].split(',') if data['allow_transfer_from']
      begin
        self.updated_at = Time.parse(data['changed'])
        self.created_at = Time.parse(data['created'])
      rescue
        # Ignore missing or invalid time stamps.
      end
    end

    # Not implemented.
    def enable_dnssec!; end # :nodoc:


    # View DNSec Params
    #
    # not implemented.
    def sec_params; [] end # :nodoc:

    def save
      if self.id.nil?
        create!
        return AutoDNS::DNS.find(@client, self.id) if self.errors.empty?
        false # Because we failed to create it!
      else
        update!
      end
    end

    def update!
      return false unless valid_zone?
      data = <<EOF
<task>
  <code>0202</code>
  <zone>
    <name>#{self.name}</name>
    <system_ns>#{self.features[:primary_ns]}</system_ns>    
    <ns_action>complete</ns_action>
    <allow_transfer_from>#{self.axfr_ips.join(',')}</allow_transfer_from>
    #{formatted_soa}
    #{formatted_ns.join('')}
    #{formatted_records.join('')}
  </zone>
</task>
EOF

      result = @client.exec!('post', nil, data)
      response = result.dig('response', 'result')
      if response.dig('status', 'type') == 'error'
        self.errors << response
        return false
      end
      true
    end

    # Create a Zone
    # (pg. 168)
    #
    # Example response from AutoDNS
    #     {"response"=>
    #          {"result"=>
    #               {"data"=>nil,
    #                "status"=>
    #                    {"code"=>"S0201",
    #                     "text"=>"Zone has been stored successfully on the nameserver.",
    #                     "type"=>"success",
    #                     "object"=>{"type"=>"zone", "value"=>"cmptstks.com"}}},
    #           "stid"=>"20180417-app2-94130"}}
    def create!
      return false unless valid_zone?
      data = <<EOF
<task>
  <code>0201</code>
  <zone>
    <name>#{self.name}</name>
    <ns_action>complete</ns_action>
    <www_include>0</www_include>
    <allow_transfer_from>#{self.axfr_ips.join(',')}</allow_transfer_from>
    <soa>
      <level>1</level>
      <email>#{self.soa_email}</email>
    </soa>
    #{formatted_ns.join('')}
  </zone>
</task>
EOF
      result = @client.exec!('post', nil, data)
      response = result.dig('response', 'result')
      if response.dig('status', 'type') == 'error'
        if response.dig('msg', 'text')
          self.errors << response.dig('msg', 'text')
        else
          self.errors << response
        end
      end
      if response.dig('status', 'type') == 'success'
        self.id = response.dig('status', 'object', 'value') if response.dig('status', 'object', 'type') == 'zone'
      end
    end

    def destroy
      return false if self.id.nil?
      return false if self.features[:primary_ns].nil?
      data = <<EOF
<task>
  <code>0203</code>
  <zone>
    <name>#{self.name}</name>
    <system_ns>#{self.features[:primary_ns]}</system_ns>
  </zone>
</task>
EOF
      result = @client.exec!('post', nil, data)
      response = result.dig('response', 'result')
      if response.dig('status', 'type') == 'error'
        self.errors << response
      end
    end

    class << self


      # Not implemented in AutoDNS
      def list_all_zones(client)
        []
      end

      # Get a zone
      # pg. 179
      #
      # <b>Example Response:</b>
      #
      #     {"response"=>
      #       {"result"=>
      #         {"data"=>
      #           {"zone"=>
      #             {"changed"=>"2018-04-05 00:08:32",
      #              "created"=>"2018-04-05 00:08:16",
      #              "name"=>"computestacks.es",
      #              "main"=>{"value"=>"62.116.130.8", "ttl"=>"300"},
      #              "ns_action"=>"complete",
      #              "www_include"=>"0",
      #              "allow_transfer_from"=>"45.79.134.147,109.71.53.103", # May not always be present.
      #              "soa"=>{"refresh"=>"43200", "retry"=>"7200", "expire"=>"1209600", "ttl"=>"86400", "email"=>"domains@computestacks.com", "default"=>"86400"},
      #              "nserver"=>[{"name"=>"ns1.auto-dns.com"}, {"name"=>"ns2.auto-dns.com"}, {"name"=>"ns3.autodns.nl"}, {"name"=>"ns4.autodns.nl"}],
      #              "rr"=>[{"name"=>"*", "ttl"=>"300", "type"=>"A", "value"=>"62.116.130.8"}, {"name"=>nil, "ttl"=>"300", "type"=>"A", "value"=>"62.116.130.8"}],
      #              "system_ns"=>"ns1.auto-dns.com",
      #              "domainsafe"=>"0",
      #              "owner"=>{"user"=>"computestacks", "context"=>"33004"},
      #              "updated_by"=>{"user"=>"computestacks", "context"=>"33004"},
      #              "comment"=>nil}},
      #          "status"=>
      #           {"code"=>"S0205", "text"=>"Zone information was inquired successfully.", "type"=>"success", "object"=>{"type"=>"zone", "value"=>"computestacks.es"}}},
      #        "stid"=>"20180416-app3-22426"}}
      #
      # <b>Example Not Found:</b>
      #
      #     {"response"=>
      #       {"result"=>
      #         {"data"=>nil,
      #          "msg"=>{"text"=>"No such zone exists.", "code"=>"EF02020", "type"=>"error", "object"=>{"type"=>"zone", "value"=>"computestack.se"}},
      #          "status"=>
      #           {"code"=>"E0205", "text"=>"Zone information could not be inquired.", "type"=>"error", "object"=>{"type"=>"zone", "value"=>"computestack.se"}}},
      #        "stid"=>"20180416-app3-22605"}}
      #
      def find(client, zone_name)

        req_data = <<EOF
<task>
  <code>0205</code>
  <zone>
    <name>#{zone_name}</name>
    <system_ns>#{ AutoDNS.config[:master_ns] }</system_ns>
  </zone>
</task>
EOF

        response = client.exec!('post', nil, req_data)['response']['result']
        return nil unless response['status']['type'] == 'success' # Not Found
        AutoDNS::Dns::Zone.new(client, response['status']['object']['value'], response['data']['zone'])
      end

    end

    private

    # Process Records
    #
    # Take raw records from server and create AutoDNS::Dns::ZoneRecords objects.
    def process_records!(data)
      records = default_records

      # TODO: Migrate SOA to zone, not as a record.
      soa = AutoDNS::Dns::ZoneRecord.new(nil, nil, self.name, {})
      soa.type = 'SOA'
      soa.refresh = data['soa']['refresh'].to_i
      soa.retry = data['soa']['retry'].to_i
      soa.expire = data['soa']['expire'].to_i
      soa.ttl = data['soa']['ttl'].to_i
      soa.email = data['soa']['email']
      soa.default = data['soa']['default'].to_i
      records['SOA'] << soa

      self.soa_email = soa.email

      data['nserver'].each do |ns|
        record_data = {
            'name' => self.name,
            'type' => 'NS',
            'ttl' => data['soa']['default'].to_i,
            'value' => ns['name']
        }
        records['NS'] << AutoDNS::Dns::ZoneRecord.new(nil, nil, self.name, record_data)
      end
      if data['rr'].is_a?(Hash)
        records[data['rr']['type']] << AutoDNS::Dns::ZoneRecord.new(nil, nil, self.name, data['rr'])
      elsif data['rr'].is_a?(Array)
        data['rr'].each do |i|
          type = i['type']
          records[type] << AutoDNS::Dns::ZoneRecord.new(nil, nil, self.name, i)
        end
      end

      self.records = records
    end

    def default_records
      {
          'A' => [],
          'AAAA' => [],
          'CAA' => [],
          'CNAME' => [],
          'DS' => [],
          'HINFO' => [],
          'MX' => [],
          'NAPTR' => [],
          'NS' => [],
          'PTR' => [],
          'SRV' => [],
          'SOA' => [],
          'SSHFP' => [],
          'TLSA' => [],
          'TXT' => []
      }
    end

    # SOA formatted
    def formatted_soa
      soa = self.records['SOA'].first
      return '<soa></soa>' if soa.nil?
      <<EOF
<soa>
  <refresh>#{soa.refresh}</refresh>
  <retry>#{soa.retry}</retry>
  <expire>#{soa.expire}</expire>
  <ttl>#{soa.ttl}</ttl>
  <email>#{self.soa_email}</email>  
</soa>
EOF
    end

    def formatted_ns
      ns = []
      if self.records['NS'].empty? # Fall back to default NS.
        AutoDNS.config[:nameservers].each do |i|
          ns << "<nserver><name>#{i}</name><ttl>#{AutoDNS.config[:ns_ttl]}</ttl></nserver>"
        end
      else
        self.records['NS'].each do |i|
          ns << "<nserver><name>#{i.hostname}</name><ttl>#{i.ttl}</ttl></nserver>"
        end
      end
      ns
    end

    def formatted_records
      rrs =[]
      self.records.each_key do |i|
        next if i == 'NS' || i == 'SOA'
        self.records[i].each do |ii|
          rrs << ii.raw_record
        end
      end
      rrs
    end

    def valid_zone?
      self.errors << "Invalid SOA email address." if /^[^@]+@[^@]+\.[^@]+$/.match(self.soa_email).nil?
      self.errors << "Missing domain name" if self.name.to_s.length < 3
      return false unless self.errors.empty?
      true
    end

  end
end
