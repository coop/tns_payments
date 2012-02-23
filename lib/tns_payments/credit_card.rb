module TNSPayments
  class CreditCard
    FORM_RESPONSE_MAPPING = {:gatewayCardExpiryDateYear => :year, :gatewayCardExpiryDateMonth => :month, :gatewayCardNumber => :number, :gatewayCardSecurityCode => :verification_value}.freeze

    def initialize args = {}
    end
  end
end
