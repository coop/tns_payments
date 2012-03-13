module TNSPayments
  class Response
    attr_reader :response

    def initialize response
      @response = JSON.parse response
    end

    def nested_response
      JSON.parse @response.fetch('response') { '{}' }
    end

    def success?
      %w[SUCCESS OPERATING].include? @response['result'] || @response['status']
    end

    def message
      if nested_response['result'] == 'ERROR'
        nested_response['error']['explanation']
      else
        'Successful request'
      end
    end
  end
end
