require 'json'
require 'rest-client'

module TNSPayments
  class Request
    attr_accessor :connection, :method, :path, :payload

    def initialize connection, method, path, payload = nil
      self.connection = connection
      self.method     = method
      self.path       = path
      self.payload    = payload
    end

    # Public: A hash representing the headers for the request.
    #
    # Returns a hash of headers.
    def headers
      headers = {}
      headers[:accept]        = '*/*'
      headers[:content_type]  = 'Application/json;charset=UTF-8'
      headers[:Authorization] = encode_credentials
      headers
    end

    # Public: Execute the request.
    #
    # Returns a response object.
    def perform
      args = {
        :method       => method,
        :url          => url,
        :headers      => headers,
        :timeout      => 120,
        :open_timeout => 30
      }
      args[:payload] = payload.to_json if payload

      Response.new RestClient::Request.execute(args)
    rescue RestClient::Exception => e
      response = e.response

      if e.is_a?(RestClient::RequestTimeout)
        response = JSON.generate({:error => {:cause => 'REQUEST_TIMEDOUT'}})
      end

      ErrorResponse.new response
    end

  private

    def encode_credentials
      credentials = ["merchant.#{connection.merchant_id}:#{connection.api_key}"].pack("m*").delete("\n")

      "Basic #{credentials}"
    end

    def url
      "#{connection.host}/api/rest/version/30#{path}"
    end
  end
end
