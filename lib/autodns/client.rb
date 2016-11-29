module Autodns
  class Client

    attr_accessor :endpoint,
                  :auth,
                  :api_version

    def initialize(endpoint, auth, data = {})
      self.endpoint = endpoint
      self.auth = auth
      self.api_version = version
    end

    def version
      nil
    end

    def exec!(http_method, path, data = nil)
      url_base = self.endpoint
      opts = {timeout: 40}
      data = '<?xml version="1.0" encoding="UTF-8"?><request>' + self.auth.auth_obj + data + '</request>' unless data.nil?
      response = case http_method
        when 'get'
          HTTParty.get(url_base, opts)
        when 'post'
          HTTParty.post(url_base, opts.merge!(body: data))
        when 'put'
          HTTParty.patch(url_base, opts.merge!(body: data))
        when 'delete'
          HTTParty.delete(url_base, opts)
      end
      acceptable_codes = [200,201,204]
      begin
        rsp_code = response.code
      rescue
        raise GeneralError, 'Fatal Error: Unable to retrieve HTTP Status code.'
      end
      if rsp_code == 404
        raise UnknownObject
      elsif rsp_code == 401
        raise AuthenticationFailed, 'Invalid Login Credentials.'
      elsif !acceptable_codes.include?(rsp_code)
        raise GeneralError, response.body
      end
      response
    end

  end
end
