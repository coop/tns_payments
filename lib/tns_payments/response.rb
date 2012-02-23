module TNSPayments
  class Response
    extend Forwardable

    attr_reader :response

    def_delegators :credit_card, :card_type

    def initialize body
      @response = body
      @result   = @response['result'] || @response['status']
    end

    def credit_card
      @credit_card ||= Tns::CreditCard.new @response['card']
    end

    def success?
      %w[SUCCESS OPERATING].include? @result
    end
  end
end
