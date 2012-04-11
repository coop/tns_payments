require 'forwardable'

module TNSPayments
  class Response
    extend Forwardable

    attr_reader :raw_response
    attr_writer :response

    def_delegators :@raw_response, :code, :cookies, :headers

    def initialize response
      @raw_response = response
    end

    # Public: The parsed response.
    #
    # Returns a hash of the parsed response.
    def response
      @response ||= JSON.parse(raw_response)
    end

    # Public: Determine if the request was successful.
    #
    # Returns boolean.
    def success?
      %w[SUCCESS OPERATING].include? response['result'] || response['status']
    end

    def message
      result = response['response'].fetch('result') { 'SUCCESS' }
      if result == 'ERROR'
        response['response']['error']['explanation']
      else
        'Successful request'
      end
    end
  end
end
