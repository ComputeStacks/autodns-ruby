# PowerDNS Client
#
module AutoDNS
  class Client

    attr_accessor :endpoint,
                  :auth,
                  :api_version

    def initialize(endpoint, auth, data = {})
      self.endpoint = endpoint.nil? ? AutoDNS.config[:endpoint] : endpoint
      self.auth = auth
      self.api_version = version
    end

    def version # :nodoc:
      0 # not implemented
    end

    def exec!(http_method, path, req_data)

      data = '<?xml version="1.0" encoding="UTF-8"?><request>' + auth.auth_obj + req_data + '</request>'

      rsp_headers = { 'Content-Type' => 'application/xml', 'Accept' => 'application/xml' }
      opts = { timeout: 40, headers: rsp_headers }

      response = case http_method
        when 'get'
          HTTParty.get(endpoint, opts)
        when 'post'
          HTTParty.post(endpoint, opts.merge!(body: data))
        when 'put'
          HTTParty.patch(endpoint, opts.merge!(body: data))
        when 'delete'
          HTTParty.delete(endpoint, opts)
      end
      response
    end

  end
end
