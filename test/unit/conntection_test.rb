require 'helper'
require 'webmock/minitest'

class TNSPayments::ConnectionTest < MiniTest::Unit::TestCase
  def setup
    @api_key     = '123api456'
    @merchant_id = 'MERCHANT'
    @gateway     = Connection.new :api_key => @api_key, :merchant_id => @merchant_id
  end

  def test_available_is_true_when_tns_gateway_is_operating
    stub_availability_request.
      to_return(:status => 200, :body => '{"status":"OPERATING"}', :headers => {})
    assert @gateway.available?
  end

  def test_available_is_false_when_tns_gateway_is_not_operating
    stub_availability_request.
      to_return(:status => 200, :body => '{"status":"EPIC_FAIL"}', :headers => {})
    refute @gateway.available?
  end

  def test_purchase_with_session_token_makes_a_successful_purchase
    stub_successful_session_token_purchase_request :amount => 100, :token => 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    response = @gateway.purchase 100, 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    assert response.success?
  end

  def test_purchase_with_session_token_makes_an_unsuccessful_purchase
    stub_unsuccessful_session_token_purchase_request :amount => 100, :token => 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    response = @gateway.purchase 100, 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_purchase_with_session_token_can_deal_with_timeout_errors
    stub_session_token_purchase_request(:amount => 100, :token => 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123').
      to_timeout
    response = @gateway.purchase 100, 'SESSIONTOKEN', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_purchase_with_credit_card_token_makes_a_successful_purchase
    stub_successful_credit_card_token_purchase_request(:amount => 100, :token => '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123')
    assert @gateway.purchase(100, '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123').success?
  end

  def test_purchase_with_credit_card_token_makes_an_unsuccessful_purchase
    stub_unsuccessful_credit_card_token_purchase_request :amount => 100, :token => '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    response = @gateway.purchase 100, '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_purchase_with_credit_card_token_can_deal_with_timeout_errors
    stub_credit_card_token_purchase_request(:amount => 100, :token => '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123').
      to_timeout
    response = @gateway.purchase 100, '9111111111111111', :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_refund_makes_successful_refund
    stub_successful_refund_request :amount => 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    response = @gateway.refund 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    assert response.success?
  end

  def test_refund_makes_unsuccessful_refund
    stub_unsuccessful_refund_request :amount => 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    response = @gateway.refund 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_refund_can_deal_with_timeout_errors
    stub_refund_request(:amount => 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123').
      to_timeout
    response = @gateway.refund 100, :order_id => 1, :transaction_id => 1, :order_reference => 'AUD123'
    refute response.success?
  end

  def test_create_credit_card_token_successfully_stores_creditcard
    stub_successful_create_credit_card_token_request
    assert @gateway.create_credit_card_token.success?
  end

  def test_create_credit_card_token_returns_valid_card_token_when_successful
    stub_successful_create_credit_card_token_request
    token = @gateway.create_credit_card_token.response['cardToken']
    assert_equal 16, token.size
    assert_match Connection::CREDIT_CARD_TOKEN_FORMAT, token
  end

  def test_create_credit_card_token_unsuccessfully_attempts_to_store_credit_card
    stub_unsuccessful_create_credit_card_token_request
    refute @gateway.create_credit_card_token.success?
  end

  def test_delete_credit_card_token_successfully_deletes_a_stored_credit_card_token
    stub_successful_delete_credit_card_token_request
    assert @gateway.delete_credit_card_token('9123456781234567').success?
  end

  def test_delete_credit_card_token_unsuccessfully_attempts_to_delete_a_stored_credit_card
    stub_unsuccessful_delete_credit_card_token_request
    refute @gateway.delete_credit_card_token('9123456781234567').success?
  end

  def test_session_token_returns_token
    stub_successful_session_token_request
    assert_equal 'SESSIONTOKEN', @gateway.session_token
  end

private

  def stub_availability_request
    stub_request(:get, "https://secure.ap.tnspayments.com/api/rest/version/4/information").
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'})
  end

  def stub_successful_refund_request options = {}
    stub_refund_request(options).
      to_return :status => 200, :headers => {}, :body => <<-EOS
         {"merchant":"#{@merchant_id}","order":{"id":#{@gateway.send(:create_order_id, options[:order_id])},"totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},
          "response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},
          "amount":#{options[:amount]},"authorizationCode":"000582","batch":20110707,"currency":"AUD","id":"#{options[:transaction_id]}",
          "receipt":"110707000582","source":"INTERNET","terminal":"08845778","type":"REFUND"}}
          EOS
  end

  def stub_unsuccessful_refund_request options = {}
    stub_refund_request(options).
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_credit_card_token_purchase_request options = {}
    stub_credit_card_token_purchase_request(options).
      to_return(:status => 200, :body => %[{"card":{"expiry":{"month":"5","year":"13"},"number":"xxxxxxxxxxxxxxxx","scheme":"MASTERCARD"},"merchant":"","order":{"id":"#{@gateway.send(:create_order_id, options[:order_id])}","totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},"response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},"amount":"#{options[:amount]}","authorizationCode":"000576","batch":20110707,"currency":"AUD","frequency":"SINGLE","id":"72637779534c67696c54b26f220dc4d3","receipt":"110707000576","source":"INTERNET","terminal":"08845778","type":"PAYMENT"}}], :headers => {})
  end

  def stub_unsuccessful_credit_card_token_purchase_request options = {}
    stub_credit_card_token_purchase_request(options).
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_session_token_purchase_request options = {}
    stub_session_token_purchase_request(options).
      to_return(:status => 200, :body => %[{"card":{"expiry":{"month":"5","year":"13"},"number":"xxxxxxxxxxxxxxxx","scheme":"MASTERCARD"},"merchant":"","order":{"id":"#{@gateway.send(:create_order_id, options[:order_id])}","totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},"response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},"amount":"#{options[:amount]}","authorizationCode":"000576","batch":20110707,"currency":"AUD","frequency":"SINGLE","id":"72637779534c67696c54b26f220dc4d3","receipt":"110707000576","source":"INTERNET","terminal":"08845778","type":"PAYMENT"}}], :headers => {})
  end

  def stub_unsuccessful_session_token_purchase_request options = {}
    stub_session_token_purchase_request(options).
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_create_credit_card_token_request
    stub_create_credit_card_token_request.
      to_return(:status => 200, :body => %{{"result":"SUCCESS", "response":{"gatewayCode":"BASIC_VERIFICATION_SUCCESSFUL"}, "card":{"number":"xxxxxxxxxxxxxxxx", "scheme":"MASTERCARD", "expiry":{"month":"5", "year":"13"}}, "cardToken":"9102370788509763"}}, :headers => {})
  end

  def stub_unsuccessful_create_credit_card_token_request
    stub_create_credit_card_token_request.
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_delete_credit_card_token_request
    stub_delete_credit_card_token_request.
      to_return(:status => 200, :body => '{"result":"SUCCESS"}', :headers => {})
  end

  def stub_unsuccessful_delete_credit_card_token_request
    stub_delete_credit_card_token_request.
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_session_token_request
    stub_session_token_request.
      to_return(:status => 200, :body => '{"result":"SUCCESS","session":"SESSIONTOKEN"}', :headers => {})
  end

  def stub_session_token_request
    stub_request(:post, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/session/).
      with :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '2',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_session_token_purchase_request options = {}
    stub_request(:put, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/order\/#{@gateway.send(:create_order_id, options[:order_id])}\/transaction\/#{options[:transaction_id]}/).
      with :body => JSON.generate({
             'apiOperation' => 'PAY',
             'order'        => {'reference' => options[:order_reference].to_s},
             'cardDetails'  => {'session' => options[:token].to_s},
             'transaction'  => {'amount' => options[:amount].to_s, 'currency' => 'AUD', 'reference' => options[:transaction_id].to_s}
           }),
           :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '158',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_credit_card_token_purchase_request options = {}
    stub_request(:put, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/order\/#{@gateway.send(:create_order_id, options[:order_id])}\/transaction\/#{options[:transaction_id]}/).
      with :body => JSON.generate({
             'apiOperation' => 'PAY',
             'order'        => {'reference' => options[:order_reference].to_s},
             'cardDetails'  => {'cardToken' => options[:token].to_s},
             'transaction'  => {'amount' => options[:amount].to_s, 'currency' => 'AUD', 'reference' => options[:transaction_id].to_s}
           }),
           :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '164',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_refund_request options = {}
    stub_request(:put, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/order\/#{@gateway.send(:create_order_id, options[:order_id])}\/transaction\/#{options[:transaction_id]}/).
      with :body => JSON.generate({
             'apiOperation' => 'REFUND',
             'order'        => {'reference' => options[:order_reference].to_s},
             'transaction'  => {'amount' => options[:amount].to_s, 'currency' => 'AUD', 'reference' => options[:transaction_id].to_s}
           }),
           :headers => {
             'Accept'          => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '120',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_create_credit_card_token_request
    stub_request(:post, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/token/).
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'}, :body => {})
  end

  def stub_delete_credit_card_token_request
    stub_request(:delete, /https:\/\/:#{@api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@merchant_id}\/token\/\d{16}/).
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'}, :body => {})
  end
end
