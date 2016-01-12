# https://secure.ap.tnspayments.com/api/documentation/integrationGuidelines/supportedFeatures/testAndGoLive.html?locale=en_US
module TNSPayments
  module TestSupport
    class CardSession
      SAMPLE_CARDS = {
        :mastercard => {
          :number => "5123456789012346",
          :expiry => {
            :month => "5",
            :year => "17",
          },
          :securityCode => "123",
        },
        :amex => {
          :number => "345678901234564",
          :expiry => {
            :month => "5",
            :year => "17",
          },
          :securityCode => "1234",
        },
        :visa => {
          :number => "4005550000000001",
          :expiry => {
            :month => "5",
            :year => "17",
          },
          :securityCode => "123",
        },
        :visa_enrolled_3ds => {
          :number => "4508750015741019",
          :expiry => {
            :month => "05",
            :year => "17",
          },
          :securityCode => "123",
        },
        :visa_not_enrolled_3ds => {
          :number => "4005550000000001",
          :expiry => {
            :month => "05",
            :year => "17",
          },
          :securityCode => "123",
        },
      }

      def self.sample_card(card_type = :visa)
        SAMPLE_CARDS.fetch(card_type)
      end

      def self.sample(card_type = :visa, *args)
        sessionize(sample_card(card_type), *args)
      end

      def self.sessionize(card, *args)
        session = new(*args)
        session.store(card)
        session.token
      end

      def initialize(tns)
        @tns = tns
      end

      def token
        @token ||= @tns.session_token
      end

      def store(card)
        response = @tns.update_session_with_card(token, card)
        raise response.response.inspect unless response.success?
        response
      end
    end
  end
end
