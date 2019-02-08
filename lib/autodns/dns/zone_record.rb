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
      data['value'] = data['value'].gsub('"', '').strip
      case self.type
      when 'CNAME', 'NS'
        self.hostname = data['value']
      when 'A', 'AAAA'
        self.ip = data['value']
      when 'MX'
        self.priority = data['pref']
        self.hostname = data['value']
      when 'NS'
        self.hostname = data['value']
      when 'TXT'
        # For longer strings, partition into multiple "" sections.
        val = data['value']
        self.value = val&.length > 254 ? "\"#{val[0..254]}\" \"#{val[255..-1]}\"" : val
      else PTR
        self.value = data['value'].gsub('"', '').strip
      end
    end

    # Format record value specifically for PowerDNS.
    # TODO: Is this still in use?
    def raw_value
      case self.type
      when 'CNAME', 'NS'
        self.hostname
      when 'A', 'AAAA'
        self.ip
      when 'MX'
        "#{self.priority} #{self.hostname}"
      when 'TXT'
        # Strip quotes
        self.value = self.value.gsub('"', '').strip
        # For longer strings, partition into multiple "" sections.
        self.value = "\"#{self.value[0..254]}\" \"#{self.value[255..-1]}\"" if self.value.length > 254
      else # PTR
        self.value.strip
      end
    end

    def raw_record
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

      else # TXT, PTR
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
