##
# Will automatically load the zone. To test if the zone actually exists, look at records. Empty records = no zone record.
module Autodns::Dns
  class Zone

    attr_accessor :id,
                  :name,
                  :records,
                  :dnssec,
                  :account_id,
                  :features,
                  :updated_at,
                  :created_at

    def initialize(client, id, data = {})
      @client = client
      self.id = id
      self.records = []
      self.dnssec = false
      self.features = {}
      load!(data) unless id.nil?
    end

    def load!(data = {})
      zone_data = '<task><code>0205</code>'
      zone_data += "<zone><name>#{self.id}</name>"
      zone_data += '<system_ns>ns1.auto-dns.com</system_ns>'
      zone_data += '</zone></task>'
      data = @client.exec!('post', nil, zone_data)
      begin
        return nil if data['response']['result']['data'].nil?
      rescue
        return nil
      else
        process_records!(data)
      end
    end

    def zone
      # ?
    end

    def save
      update!
    end

    def update!
      zone_data = '<task><code>0202</code>'
      zone_data += "<zone><name>#{self.id}</name>"
      zone_data += "<system_ns>#{self.features['system_ns']}</system_ns><ns_action>complete</ns_action>"
      zone_data += '<soa>'
      zone_data += "<refresh>#{self.features['soa']['refresh']}</refresh><retry>#{self.features['soa']['retry']}</retry><expire>#{self.features['soa']['expire']}</expire><ttl>#{self.features['soa']['ttl']}</ttl><email>#{self.features['soa']['email']}</email><default>#{self.features['soa']['default']}</default>"
      zone_data += '</soa>'
      self.features['ns'].each do |i|
        zone_data += "<nserver><name>#{i['name']}</name><ttl>86400</ttl></nserver>"
      end
      ungrouped_records.each do |i|
        zone_data += "<rr><name>#{i.name}</name><ttl>#{i.ttl}</ttl><type>#{i.type}</type><value>#{i.value}</value></rr>"
      end
      zone_data += '</zone></task>'
      begin
        response = @client.exec!('post', nil, zone_data)
      rescue => e
        return Autodns::Response.new(false, e.to_s)
      end
      begin
        Autodns::Response.new(response['response']['result']['status']['type'] == 'success', response['response']['result']['status']['text'], response['response'])
      rescue => e
        return Autodns::Response.new(false, e.to_s)
      end
    end

    def create!
      raise NotImplemented
    end

    def destroy
      raise NotImplemented
    end

    private

    # Convert 'process_records' to just an array of records
    def ungrouped_records
      val = []
      self.records.each_with_index do |(i,v),k|
        val << v
      end
      val.flatten!
    end

    # Take records and place them into groups for easy rendering client side.
    def process_records!(data)
      records = {
        'SOA' => [],
        'A' => [],
        'AAAA' => [],
        'MX' => [],
        'CNAME' => [],
        'TXT' => [],
        'NS' => [],
        'SRV' => [],
        'PTR' => []
      }
      begin
        rrsets = data['response']['result']['data']['zone']['rr']
      rescue
        self.records = []
        return true
      else
        rrsets = rrsets.nil? ? [] : rrsets
        if rrsets.is_a?(Hash)
          ar = []
          ar << rrsets
          rrsets = ar
        end
      end
      self.features = {
        'system_ns' => data['response']['result']['data']['zone']['system_ns'],
        'soa' => {
          'refresh' => data['response']['result']['data']['zone']['soa']['refresh'].to_i,
          'retry' => data['response']['result']['data']['zone']['soa']['retry'].to_i,
          'expire' => data['response']['result']['data']['zone']['soa']['expire'].to_i,
          'ttl' => data['response']['result']['data']['zone']['soa']['ttl'].to_i,
          'email' => data['response']['result']['data']['zone']['soa']['email'],
          'default' => data['response']['result']['data']['zone']['soa']['default'].to_i
        },
        'ns' => []
      }
      data['response']['result']['data']['zone']['nserver'].each do |i|
        self.features['ns'] << {'name' => i['name'], 'ttl' => 86400}
      end
      rrsets.each do |i|
        zone_record = Autodns::Dns::ZoneRecord.new(nil, nil, nil, {})
        zone_record.name = i['name']
        zone_record.type = i['type']
        zone_record.ttl = i['ttl'].to_i
        zone_record.value = i['value']
        records[i['type']] << zone_record
      end
      self.records = records
    end

  end
end
