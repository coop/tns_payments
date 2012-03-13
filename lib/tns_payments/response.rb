module TNSPayments
  class Response
    attr_reader :response

    def initialize response
      @response = JSON.parse response
    end

    def body
      JSON.parse response.fetch('response') { '{}' }
    end

    def success?
      %w[SUCCESS OPERATING].include? response['result'] || response['status']
    end

    def message
      if body['result'] == 'ERROR'
        body['error']['explanation']
      else
        'Successful request'
      end
    end
  end
end
