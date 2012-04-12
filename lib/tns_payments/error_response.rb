module TNSPayments
  class ErrorResponse < Response
    # Public: Check if the request was rejected because it did not conform to
    #         the API protocol.
    #
    # Returns booelan.
    def invalid_request?
      cause == 'INVALID_REQUEST'
    end

    # Public: Check if the server did not have enough resources to process the
    #         request at the moment.
    #
    # Returns booelan.
    def server_busy?
      cause == 'SERVER_BUSY'
    end

    # Public: Check if the request was rejected due to security reasons such as
    #         firewall rules, expired certificate, etc.
    #
    # Returns booelan.
    def request_rejected?
      cause == 'REQUEST_REJECTED'
    end

    # Public: Check if there was an internal system failure.
    #
    # Returns booelan.
    def server_failed?
      cause == 'SERVER_FAILED'
    end

    # Public: Check if the request timed out.
    #
    # Returns boolean.
    def timedout?
      cause == 'REQUEST_TIMEDOUT'
    end

    # Public: Broadly categorizes the cause of the error.
    #
    # Returns string.
    def cause
      response['error']['cause']
    end

    # Pubic: Textual description of the error based on the cause.
    #
    # Returns string.
    def explanation
      if invalid_request? || server_busy?
        response['error']['explanation']
      else
        "No explanation available for #{cause}"
      end
    end

    # Public: Indicates the name of the field that failed validation.
    #
    # Returns name of invalid field.
    def field
      response['error']['field'] if invalid_request?
    end

    # Public: Indicates the code that helps the support team to quickly
    #         identify the exact cause of the error.
    #
    # Returns a support code.
    def support_code
      if server_failed? || request_rejected?
        response['error']['supportCode']
      else
        "No support code for #{cause}"
      end
    end

    # Public: Determine if the request was successful.
    #
    # Returns false.
    def success?
      false
    end

    # Public: A system-generated high level overall result of the operation.
    #
    # Returns string.
    def result
      response['result']
    end
  end
end
