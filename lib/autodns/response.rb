module Autodns
  class Response

    attr_accessor :successful,
                  :message,
                  :data

    def initialize(successful, message, data = nil)
      self.successful = successful
      self.message = message
      self.data = data
    end

    def success?
      self.successful
    end

  end
end
