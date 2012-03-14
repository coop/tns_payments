module TNSPayments
  class Response
    attr_reader :raw_response

    def initialize response
      @raw_response = response
    end

    def response
      @response ||= JSON.parse(raw_response)
    end

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
