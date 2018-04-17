# PowerDNS Authentication Object
# (0, 'admin', 'webserver-password', 'api-key')
module AutoDNS
  class Auth

    attr_accessor :user_id,
                  :username,
                  :password,
                  :api_key

    def initialize(user_id, username, password, api_key = nil)
      self.user_id = user_id
      self.username = username
      self.password = password
      self.api_key = api_key.nil? ? '33004' : api_key
    end

    def auth_obj
      "<auth><user>#{self.username}</user><password>#{self.password}</password><context>#{self.api_key}</context></auth>"
      # {
      #     auth: {
      #         user: username,
      #         password: password,
      #         context: api_key
      #     }
      # }
    end

  end
end
