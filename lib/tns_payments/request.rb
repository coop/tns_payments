require 'json'
require 'rest-client'

module TNSPayments
  class Request
    attr_accessor :connection, :method, :path, :options

    def initialize connection, method, path, options = {}
      self.connection, self.method, self.path, self.options = connection, method, path, options
    end

    def perform
      authorization = options.fetch(:authorization) { true }
      url           = "#{connection.host}/api/rest/version/4#{path}"
      auth_headers  = {:Authorization => encode_credentials}
      headers       = {:content_type => 'Application/json;charset=UTF-8', :accept => '*/*'}
      headers.merge! auth_headers if authorization

      args = [headers]
      args.unshift(options.to_json) unless [:delete, :get, :head].include? method

      Response.new RestClient.send(method, url, *args)
    rescue RestClient::Exception => e
      Response.new({:result => e.message.upcase, :response => JSON.parse(e.response || '{}')}.to_json)
    end

  private

    def encode_credentials
      'Basic ' + Base64.encode64(":#{connection.api_key}")
    end
  end
end
