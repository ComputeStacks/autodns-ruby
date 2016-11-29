# AutoDNS Authentication Object
# (0, 'autodns-user', 'autdns-password', 'autodns-context')
module Autodns
  class Auth

    attr_accessor :user_id,
                  :username,
                  :password,
                  :api_key

    def initialize(user_id, username, password, api_key)
      self.user_id = user_id
      self.username = username
      self.password = password
      self.api_key = api_key
    end

    def auth_obj
      "<auth><user>#{self.username}</user><password>#{self.password}</password><context>#{self.api_key.to_i}</context></auth>"
    end

  end
end
