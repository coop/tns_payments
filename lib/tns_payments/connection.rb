require 'base64'

module TNSPayments
  class Connection
    CREDIT_CARD_TOKEN_FORMAT = /^9\d{15}/

    attr_accessor :api_key, :host, :merchant_id
    attr_writer :session_token

    # Public: Request to check that the gateway is operating.
    #
    # Returns a boolean.
    def available?
      request(:get, '/information', :authorization => false).success?
    end

    def initialize options
      self.api_key, self.merchant_id = options[:api_key], options[:merchant_id]
      self.host = options.fetch(:host) { 'https://secure.ap.tnspayments.com' }
    end

    # Public: Payment form url that includes a session token.
    #
    # Returns a url.
    def payment_form_url
      "#{host}/form/#{session_token}"
    end

    # Public: A single transaction to authorise the payment and transfer funds
    #         from the cardholder's account to your account.
    #
    # Returns a Response object.
    def purchase transaction, token
      transaction    = Transaction.new transaction
      order_id       = transaction.order_id
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'PAY',
        'cardDetails'  => card_details(token),
        'order'        => {'reference' => transaction.reference},
        'transaction'  => {
          'amount'    => transaction.amount.to_s,
          'currency'  => transaction.currency,
          'reference' => transaction.reference
        }
      }

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    # Public: Request to refund previously captured funds.
    #
    # Returns a Response object.
    def refund transaction
      transaction    = Transaction.new transaction
      order_id       = transaction.order_id.to_i
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'REFUND',
        'transaction'  => {
          'amount'    => transaction.amount.to_s,
          'currency'  => transaction.currency,
          'reference' => transaction_id.to_s
        }
      }

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    # Public: Request to store a card for later retrieval via token.
    #
    # Returns a Response object.
    def create_credit_card_token token
      params = {
        'cardDetails' => card_details(token)
      }

      request :post, "/merchant/#{merchant_id}/token", params
    end

    # Public:
    #
    # Returns a Response object.
    def delete_credit_card_token token
      request :delete, "/merchant/#{merchant_id}/token/#{token}"
    end

    # Public: Request to create a Form Session. A Form Session is used by the
    #         Hosted Payment Form service to temporarily store card details so
    #         that the merchant does not need to handle these details directly.
    #
    # Returns a Response object.
    def session_token
      @session_token ||= begin
        response = request :post, "/merchant/#{merchant_id}/session"
        if response.success?
          response.response.fetch('session')
        else
          raise SessionTokenException.new, response.explanation
        end
      end
    end

    # Public: Request to check a cardholder's enrollment in the 3DSecure scheme.
    #
    # Returns a Response object.
    def check_enrollment transaction, token, postback_url
      params = {
        '3DSecure'     => {
          'authenticationRedirect' => {
            'pageGenerationMode'   => 'CUSTOMIZED',
            'responseUrl'          => postback_url
          }
        },
        'apiOperation' => 'CHECK_3DS_ENROLLMENT',
        'cardDetails'  => card_details(token),
        'transaction'  => {
          'amount'   => transaction.amount.to_s,
          'currency' => transaction.currency
        }
      }

      request :put, "/merchant/#{merchant_id}/3DSecureId/#{transaction.three_domain_id}", params
    end

    # Public: Interprets the authentication response returned from the card
    #         Issuer's Access Control Server (ACS) after the cardholder
    #         completes the authentication process.
    #
    # Returns a Response object.
    def process_acs_result three_domain_id, pa_res
      params = {
        '3DSecure'     => {'paRes' => pa_res},
        'apiOperation' => 'PROCESS_ACS_RESULT'
      }

      request :post, "/merchant/#{merchant_id}/3DSecureId/#{three_domain_id}", params
    end

  private

    def card_details token
      {token_key(token) => token}
    end

    def token_key token
      token =~ CREDIT_CARD_TOKEN_FORMAT ? 'cardToken' : 'session'
    end

    def request method, path, options = {}
      Request.new(self, method, path, options).perform
    end
  end
end
