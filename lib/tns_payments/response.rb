module TNSPayments
  class Response
    attr_reader :response

    def initialize response
      @response = JSON.parse response
    end

    def success?
      %w[SUCCESS OPERATING].include? response['result'] || response['status']
    end
  end
end
