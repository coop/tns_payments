require 'json'
require 'rest-client'

module TNSPayments
  class Request
    attr_accessor :connection, :method, :path, :payload

    def initialize connection, method, path, payload = {}
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
      headers[:Authorization] = encode_credentials if authorization
      headers
    end

    # Public: Execute the request.
    #
    # Returns a response object.
    def perform
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
      response = e.response

      if e.is_a?(RestClient::RequestTimeout)
        response = JSON.generate({:error => {:cause => 'REQUEST_TIMEDOUT'}})
      end

      ErrorResponse.new response
    end

  private

    def authorization
      payload.fetch(:authorization) { true }
    end

    def encode_credentials
      credentials = ["merchant.#{connection.merchant_id}:#{connection.api_key}"].pack("m*").delete("\n")

      "Basic #{credentials}"
    end

    def url
      "#{connection.host}/api/rest/version/32#{path}"
    end
  end
end
