require 'base64'
require 'json'
require 'rest-client'

module TNSPayments
  class Connection
    CREDIT_CARD_TOKEN_FORMAT = /^9/ # /\d{16}/

    attr_writer :session_token

    def available?
      request(:get, '/information', :authorization => false).success?
    end

    def initialize options
      @api_key     = options[:api_key]
      @merchant_id = options[:merchant_id]
    end

    def payment_form_url
      "https://secure.ap.tnspayments.com/form/#{session_token}"
    end

    def purchase transaction, token
      order_id       = transaction.order_id
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'PAY',
        'order'        => {'reference'               => transaction.reference},
        'cardDetails'  => {purchase_token_key(token) => token},
        'transaction'  => {'amount'                  => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction_id.to_s}
      }

      request :put, "/merchant/#{@merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    def refund transaction
      order_id       = transaction.order_id
      transaction_id = transaction.transaction_id
      params         = {
        'apiOperation' => 'REFUND',
        'order'        => {'reference' => transaction.reference},
        'transaction'  => {'amount'    => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction_id.to_s}
      }

      request :put, "/merchant/#{@merchant_id}/order/#{order_id}/transaction/#{transaction_id}", params
    end

    def create_credit_card_token
      request :post, "/merchant/#{@merchant_id}/token"
    end

    def delete_credit_card_token token
      request :delete, "/merchant/#{@merchant_id}/token/#{token}"
    end

    def session_token
      @session_token ||= begin
        response = request :post, "/merchant/#{@merchant_id}/session"
        response.success?? response.response['session'] : raise(response.response.inspect)
      end
    end

  private

    def api_url
      'https://secure.ap.tnspayments.com/api/rest/version/4'
    end

    def encode_credentials
      credentials = ['', @api_key].join(':')
      'Basic ' << Base64.encode64(credentials)
    end

    def purchase_token_key token
      token =~ CREDIT_CARD_TOKEN_FORMAT ? 'cardToken' : 'session'
    end

    def request method, path, options = {}
      authorization = options.fetch(:authorization) { true }
      url           = api_url << path
      auth_headers  = {:Authorization => encode_credentials}
      headers       = {:content_type => 'Application/json;charset=UTF-8', :accept => '*/*'}
      headers.merge! auth_headers if authorization

      args = [headers]
      args.unshift(options.to_json) unless [:delete, :get, :head].include? method

      Response.new JSON.parse(RestClient.send(method, url, *args))
    rescue RestClient::Exception => e
      Response.new 'result' => e.message.upcase, 'response' => e.response
    end
  end
end
