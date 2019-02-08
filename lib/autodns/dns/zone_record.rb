module AutoDNS::Dns
  class ZoneRecord

    attr_accessor :id,
                  :type,
                  :ip,
                  :name,
                  :hostname,
                  :priority,
                  :port,
                  :weight,
                  :value,
                  :serial,
                  :primary_dns,
                  :default, # default TTL
                  :retry,
                  :refresh,
                  :expire,
                  :email,
                  :ttl,
                  :zone_id

    def initialize(client, id, zone_id, data = {})
      self.ttl = 3600
      self.zone_id = zone_id
      load!(data) unless data.empty?
    end

    def load!(data)
      self.name = data['name'].nil? ? zone_id : data['name']
      self.ttl = data['ttl'] if data['ttl']
      self.type = data['type']
      case self.type
      when 'CNAME', 'NS'
        self.hostname = data['value'].gsub('"', '').strip
      when 'A', 'AAAA'
        self.ip = data['value'].gsub('"', '').strip
      when 'MX'
        self.priority = data['pref']
        self.hostname = data['value'].gsub('"', '').strip
      when 'NS'
        self.hostname = data['value'].gsub('"', '').strip
      else # TXT, PTR
        if data['value'] && data['value'].length > 1
          if data['value'].split("\"").count > 1 # Split record?
            self.value = data['value'].split("\"").map {|i| i.strip unless i.length.zero?}.join("").gsub('\"','').gsub('"','')
          else
            self.value = data['value'].gsub('\"', '').gsub('"','').strip
          end
        end
      end
    end

    # Clean up values in preperation for sending to AutoDNS.
    def format!
      return true unless self.value && self.value.length > 0
      case self.type
      when 'TXT'
        self.value = self.value.strip
        # For longer strings, partition into multiple "" sections.
        if self.value.length > 254 && self.value.split("\"").count < 2
          self.value = "\"#{self.value[0..254]}\" \"#{self.value[255..-1]}\""
        else # Ensure we have quotes around our string.
          self.value = self.value.gsub('\"','').gsub('"','')
          self.value = "\"#{self.value}\""
        end
      when 'PTR'
        self.value = self.value.gsub('"', '').strip
      end
    end

    # Format record value specifically for PowerDNS.
    # def raw_value
    #   case self.type
    #   when 'CNAME', 'NS'
    #     self.hostname
    #   when 'A', 'AAAA'
    #     self.ip
    #   when 'MX'
    #     "#{self.priority} #{self.hostname}"
    #   when 'TXT'
    #     # Strip quotes
    #     self.value = self.value.gsub('"', '').strip
    #     # For longer strings, partition into multiple "" sections.
    #     self.value = "\"#{self.value[0..254]}\" \"#{self.value[255..-1]}\"" if self.value.length > 254
    #   else # PTR
    #     self.value.strip
    #   end
    # end

    def raw_record
      format!
      case self.type
      when 'NS', 'MX'
        <<EOF
<rr>
  <name>#{self.name}</name>
  <ttl>#{self.ttl}</ttl>
  <type>#{self.type}</type>
  <pref>#{self.priority}</pref>
  <value>#{self.hostname}</value>
</rr>
EOF
      when 'A', 'AAAA'
        <<EOF
<rr>
  <name>#{self.name}</name>
  <ttl>#{self.ttl}</ttl>
  <type>#{self.type}</type>
  <value>#{self.ip}</value>
</rr>
EOF
      when 'CNAME'
        <<EOF
<rr>
  <name>#{self.name}</name>
  <ttl>#{self.ttl}</ttl>
  <type>#{self.type}</type>
  <value>#{self.hostname}</value>
</rr>
EOF

      when 'TXT'
        <<EOF
<rr>
  <name>#{self.name}</name>
  <ttl>#{self.ttl}</ttl>
  <type>#{self.type}</type>
  <value>#{self.value}</value>
</rr>
EOF
      else # PTR
        <<EOF
<rr>
  <name>#{self.name}</name>
  <ttl>#{self.ttl}</ttl>
  <type>#{self.type}</type>
  <value>#{self.value}</value>
</rr>
EOF
      end
    end

  end
end
