require 'base64'
require 'active_support/ordered_hash'

module TNSPayments
  class Connection
    CREDIT_CARD_TOKEN_FORMAT = /^9\d{15}/

    attr_accessor :api_key, :host, :merchant_id
    attr_writer :session_token

    # Public: Request to check that the gateway is operating.
    #
    # Returns a boolean.
    def available?
      AvailableResponse.new(request(:get, '/information')).success?
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
      order_params = ActiveSupport::OrderedHash.new
      order_params['amount'] = transaction.amount.to_s
      order_params['currency'] = transaction.currency
      order_params['reference'] = transaction.reference
      transaction_params = ActiveSupport::OrderedHash.new
      transaction_params['reference'] = transaction.reference.to_s
      params = ActiveSupport::OrderedHash.new
      params['apiOperation'] = 'PAY'
      params['order'] = order_params
      params['transaction'] = transaction_params
      params.merge!(source_of_funds(token))

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    # Public: Request to refund previously captured funds.
    #
    # Returns a Response object.
    def refund transaction
      transaction = Transaction.new transaction
      order_id = transaction.order_id.to_i
      transaction_id = transaction.transaction_id
      transaction_params = ActiveSupport::OrderedHash.new
      transaction_params['amount'] = transaction.amount.to_s
      transaction_params['currency'] = transaction.currency
      transaction_params['reference'] = transaction.reference.to_s
      params = ActiveSupport::OrderedHash.new
      params['apiOperation'] = 'REFUND'
      params['transaction'] = transaction_params

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    # Public: Request to store a card for later retrieval via token.
    #
    # Returns a Response object.
    def create_credit_card_token token
      source_of_funds_params = ActiveSupport::OrderedHash.new
      source_of_funds_params['type'] = 'CARD'
      session_params = ActiveSupport::OrderedHash.new
      session_params['id'] = token
      params = ActiveSupport::OrderedHash.new
      params['session'] = session_params
      params['sourceOfFunds'] = source_of_funds_params

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
        result = request :post, "/merchant/#{merchant_id}/session"
        if result.success?
          result.response['session']['id']
        else
          raise SessionTokenException.new, result.explanation
        end
      end
    end

    # Public: Request to update a session token with card data.
    #
    # Returns a response object.
    def update_session_with_card(token, card)
      source_of_funds_params = ActiveSupport::OrderedHash.new
      source_of_funds_params['type'] = 'CARD'
      source_of_funds_params['provided'] = {'card' => card}
      params = {'sourceOfFunds' => source_of_funds_params}

      UpdateSessionResponse.new(request(:put, "/merchant/#{merchant_id}/session/#{token}", params))
    end

    # Public: Request to check a cardholder's enrollment in the 3DSecure scheme.
    #
    # Returns a Response object.
    def check_enrollment transaction, token, postback_url
      redirect_params = ActiveSupport::OrderedHash.new
      redirect_params['pageGenerationMode'] = 'CUSTOMIZED'
      redirect_params['responseUrl'] = postback_url
      order_params = ActiveSupport::OrderedHash.new
      order_params['amount'] = transaction.amount.to_s
      order_params['currency'] = transaction.currency
      params = ActiveSupport::OrderedHash.new
      params['apiOperation'] = 'CHECK_3DS_ENROLLMENT'
      params['3DSecure'] = {'authenticationRedirect' => redirect_params}
      params['session'] = {'id' => token}
      params['order'] = order_params

      ThreeDomainSecureResponse.new(request(:put, "/merchant/#{merchant_id}/3DSecureId/#{transaction.three_domain_id}", params))
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

      ThreeDomainSecureResponse.new(request(:post, "/merchant/#{merchant_id}/3DSecureId/#{three_domain_id}", params))
    end

  private

    def source_of_funds(token)
      params = ActiveSupport::OrderedHash.new
      funds = ActiveSupport::OrderedHash.new
      funds['type'] = 'CARD'

      if token =~ CREDIT_CARD_TOKEN_FORMAT
        funds['token'] = token
        params['sourceOfFunds'] = funds
      else
        params['sourceOfFunds'] = funds
        params['session'] = {'id' => token}
      end

      params
    end

    def request(*args)
      Request.new(self, *args).perform
    end
  end
end
