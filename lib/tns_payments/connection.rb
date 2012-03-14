require 'base64'
require 'json'
require 'rest-client'

module TNSPayments
  class Connection
    CREDIT_CARD_TOKEN_FORMAT = /^9\d{15}/

    attr_accessor :api_key, :host, :merchant_id
    attr_writer :session_token

    def available?
      request(:get, '/information', :authorization => false).success?
    end

    def initialize options
      self.api_key, self.merchant_id = options[:api_key], options[:merchant_id]
      self.host = options.fetch(:host) { 'https://secure.ap.tnspayments.com' }
    end

    def payment_form_url
      "#{host}/form/#{session_token}"
    end

    def purchase transaction, token
      order_id       = transaction.order_id
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'PAY',
        'cardDetails'  => card_details(token),
        'order'        => {'reference' => transaction.reference},
        'transaction'  => {'amount'    => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction_id.to_s}
      }

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    def refund transaction
      order_id       = transaction.order_id
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'REFUND',
        'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction_id.to_s}
      }

      request :put, "/merchant/#{merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    def create_credit_card_token
      request :post, "/merchant/#{merchant_id}/token"
    end

    def delete_credit_card_token token
      request :delete, "/merchant/#{merchant_id}/token/#{token}"
    end

    def session_token
      @session_token ||= begin
        response = request :post, "/merchant/#{merchant_id}/session"
        response.response.fetch('session') { raise(SessionTokenException.new, response.message) }
      end
    end

    def check_enrollment transaction, token
      params = {
        '3DSecure'     => {'authenticationRedirect' => {'pageGenerationMode' => 'CUSTOMIZED', 'responseUrl' => 'http://google.com/'}},
        'apiOperation' => 'CHECK_3DS_ENROLLMENT',
        'cardDetails'  => card_details(token),
        'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency}
      }

      request :put, "/merchant/#{merchant_id}/3DSecureId/#{transaction.three_d_s_id}", params
    end

  private

    def encode_credentials
      'Basic ' + Base64.encode64(":#{api_key}")
    end

    def card_details token
      {token_key(token) => token}
    end

    def token_key token
      token =~ CREDIT_CARD_TOKEN_FORMAT ? 'cardToken' : 'session'
    end

    def request method, path, options = {}
      authorization = options.fetch(:authorization) { true }
      url           = "#{host}/api/rest/version/4#{path}"
      auth_headers  = {:Authorization => encode_credentials}
      headers       = {:content_type => 'Application/json;charset=UTF-8', :accept => '*/*'}
      headers.merge! auth_headers if authorization

      args = [headers]
      args.unshift(options.to_json) unless [:delete, :get, :head].include? method

      Response.new RestClient.send(method, url, *args)
    rescue RestClient::Exception => e
      Response.new({:result => e.message.upcase, :response => JSON.parse(e.response || '{}')}.to_json)
    end
  end
end
