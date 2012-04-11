require 'json'
require 'rest-client'

module TNSPayments
  class Request
    attr_accessor :connection, :method, :path, :payload

    def initialize connection, method, path, payload = {}
      self.connection, self.method, self.path, self.payload = connection, method, path, payload
    end

    def perform
      authorization = payload.fetch(:authorization) { true }
      url           = "#{connection.host}/api/rest/version/4#{path}"
      auth_headers  = {:Authorization => encode_credentials}
      headers       = {:content_type => 'Application/json;charset=UTF-8', :accept => '*/*'}
      headers.merge! auth_headers if authorization

      args = {
        :method       => method,
        :url          => url,
        :payload      => payload.to_json,
        :headers      => headers,
        :timeout      => 120,
        :open_timeout => 30
      }

      Response.new RestClient::Request.execute(args)
    rescue RestClient::Exception => e
      # ErrorResponse.new e.response
      Response.new({:result => e.message.upcase, :response => JSON.parse(e.response || '{}')}.to_json)
    end

  private

    def encode_credentials
      'Basic ' + Base64.encode64(":#{connection.api_key}")
    end
  end
end
