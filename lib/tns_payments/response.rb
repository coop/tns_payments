module TNSPayments
  class Response
    extend Forwardable

    attr_reader :raw_response

    def initialize response
      @raw_response = response
    end

    # Public: The parsed response.
    #
    # Returns a hash of the parsed response.
    def response
      @response ||= JSON.parse(raw_response)
    end

    # Public: The result of the request.
    #
    # Returns a string.
    def result
      if response.has_key?('status')
        response['status'] == 'OPERATING' ? 'SUCCESS' : 'ERROR'
      else
        response['result']
      end
    end

    # Public: Check if the request was successful.
    #
    # Returns boolean.
    def success?
      result == 'SUCCESS'
    end

    # Public: Unuseful message.
    #
    # Returns a string.
    def message
      if success?
        'Successful request'
      else
        ErrorResponse.new(raw_response).explanation
      end
    end
  end
end
