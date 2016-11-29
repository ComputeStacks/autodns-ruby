module Autodns::Dns
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
                  :retry,
                  :refresh,
                  :expire,
                  :email,
                  :ttl,
                  :zone_id

    def initialize(client, id, zone_id, data = {})
      self.ttl = 3600
    end

  end
end
