require 'delegate'

module TNSPayments
  class Response
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
      response.fetch('result') { 'UNKNOWN' }
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

  class UpdateSessionResponse < SimpleDelegator
    def success?
      update_status == 'SUCCESS'
    end

    private

    def update_status
      response['session']['updateStatus']
    end
  end

  class AvailableResponse < SimpleDelegator
    def success?
      response['status'] == 'OPERATING'
    end
  end

  class ThreeDomainSecureResponse < SimpleDelegator
    def success?
      response.has_key?("3DSecure")
    end
  end
end
