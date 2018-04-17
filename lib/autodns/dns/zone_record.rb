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
        self.hostname = data['value']
      when 'A', 'AAAA'
        self.ip = data['value']
      when 'MX'
        self.priority = data['pref']
        self.hostname = data['value']
      when 'NS'
        self.hostname = data['value']
      else
        self.value = data['value']
      end
    end

    # Format record value specifically for PowerDNS.
    def raw_value
      case self.type
      when 'CNAME', 'NS'
        self.hostname
      when 'A', 'AAAA'
        self.ip
      when 'MX'
        "#{self.priority} #{self.hostname}"
      else
        self.value
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

      else
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
