require 'helper'
require 'webmock/minitest'

class TNSPayments::ConnectionTest < MiniTest::Unit::TestCase
  def setup
    @gateway = Connection.new :api_key => '123api456', :merchant_id => 'MERCHANT'
  end

  def test_available_is_true_when_tns_gateway_is_operating
    stub_availability_request.to_return(:status => 200, :body => '{"status":"OPERATING"}', :headers => {})
    assert @gateway.available?
  end

  def test_available_is_false_when_tns_gateway_is_not_operating
    stub_availability_request.to_return(:status => 200, :body => '{"status":"EPIC_FAIL"}', :headers => {})
    refute @gateway.available?
  end

  def test_purchase_with_session_token_makes_a_successful_purchase
    stub_successful_session_token_purchase_request mock_transaction, 'SESSIONTOKEN'
    assert @gateway.purchase(mock_transaction, 'SESSIONTOKEN').success?
  end

  def test_purchase_with_session_token_makes_an_unsuccessful_purchase
    stub_unsuccessful_session_token_purchase_request mock_transaction, 'SESSIONTOKEN'
    refute @gateway.purchase(mock_transaction, 'SESSIONTOKEN').success?
  end

  def test_purchase_with_session_token_can_deal_with_timeout_errors
    stub_session_token_purchase_request(mock_transaction, 'SESSIONTOKEN').to_timeout
    refute @gateway.purchase(mock_transaction, 'SESSIONTOKEN').success?
  end

  def test_purchase_with_credit_card_token_makes_a_successful_purchase
    stub_successful_credit_card_token_purchase_request(mock_transaction, '9111111111111111')
    assert @gateway.purchase(mock_transaction, '9111111111111111').success?
  end

  def test_purchase_with_credit_card_token_makes_an_unsuccessful_purchase
    stub_unsuccessful_credit_card_token_purchase_request mock_transaction, '9111111111111111'
    refute @gateway.purchase(mock_transaction, '9111111111111111').success?
  end

  def test_purchase_with_credit_card_token_can_deal_with_timeout_errors
    stub_credit_card_token_purchase_request(mock_transaction, '9111111111111111').to_timeout
    refute @gateway.purchase(mock_transaction, '9111111111111111').success?
  end

  def test_refund_makes_successful_refund
    stub_successful_refund_request mock_transaction
    assert @gateway.refund(mock_transaction).success?
  end

  def test_refund_makes_unsuccessful_refund
    stub_unsuccessful_refund_request mock_transaction
    refute @gateway.refund(mock_transaction).success?
  end

  def test_refund_can_deal_with_timeout_errors
    stub_refund_request(mock_transaction).to_timeout
    refute @gateway.refund(mock_transaction).success?
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

  def test_unsuccessful_session_token_request_raises_an_exception
    stub_session_token_request.to_return(:status => 400, :body => '{}')
    assert_raises SessionTokenException do
      @gateway.session_token
    end
  end

  def test_successful_check_enrollment_request_returns_card_enrolled
    transaction = mock_transaction
    transaction.expect :three_d_s_id, 'randomstring'
    stub_successful_session_token_request
    token = @gateway.session_token
    stub_successful_check_enrollment_request transaction, token
    response = @gateway.check_enrollment transaction, token
    assert_equal 'CARD_ENROLLED', response.response['response']['3DSecure']['gatewayCode']
  end

private

  def stub_availability_request
    stub_request(:get, "https://secure.ap.tnspayments.com/api/rest/version/4/information").
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'})
  end

  def stub_successful_refund_request transaction
    stub_refund_request(transaction).
      to_return :status => 200, :headers => {}, :body => <<-EOS
         {"merchant":"#{@gateway.merchant_id}","order":{"id":#{transaction.order_id},"totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},
          "response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},
          "amount":#{transaction.amount},"authorizationCode":"000582","batch":20110707,"currency":"AUD","id":"#{transaction.transaction_id}",
          "receipt":"110707000582","source":"INTERNET","terminal":"08845778","type":"REFUND"}}
          EOS
  end

  def stub_unsuccessful_refund_request transaction
    stub_refund_request(transaction).
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_credit_card_token_purchase_request transaction, token
    stub_credit_card_token_purchase_request(transaction, token).
      to_return(:status => 200, :body => %[{"card":{"expiry":{"month":"5","year":"13"},"number":"xxxxxxxxxxxxxxxx","scheme":"MASTERCARD"},"merchant":"","order":{"id":"#{transaction.order_id}","totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},"response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},"amount":"#{transaction.amount}","authorizationCode":"000576","batch":20110707,"currency":"AUD","frequency":"SINGLE","id":"72637779534c67696c54b26f220dc4d3","receipt":"110707000576","source":"INTERNET","terminal":"08845778","type":"PAYMENT"}}], :headers => {})
  end

  def stub_unsuccessful_credit_card_token_purchase_request transaction, token
    stub_credit_card_token_purchase_request(transaction, token).
      to_return(:status => 200, :body => '{"result":"FAILURE"}', :headers => {})
  end

  def stub_successful_session_token_purchase_request transaction, token
    stub_session_token_purchase_request(transaction, token).
      to_return(:status => 200, :body => %[{"card":{"expiry":{"month":"5","year":"13"},"number":"xxxxxxxxxxxxxxxx","scheme":"MASTERCARD"},"merchant":"","order":{"id":"#{transaction.order_id}","totalAuthorizedAmount":0.00,"totalCapturedAmount":0.00,"totalRefundedAmount":0.00},"response":{"acquirerCode":"00","gatewayCode":"APPROVED"},"result":"SUCCESS","transaction":{"acquirer":{"id":"STGEORGE"},"amount":"#{transaction.amount}","authorizationCode":"000576","batch":20110707,"currency":"AUD","frequency":"SINGLE","id":"72637779534c67696c54b26f220dc4d3","receipt":"110707000576","source":"INTERNET","terminal":"08845778","type":"PAYMENT"}}], :headers => {})
  end

  def stub_unsuccessful_session_token_purchase_request transaction, token
    stub_session_token_purchase_request(transaction, token).
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
    stub_request(:post, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/session/).
      with :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '2',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_session_token_purchase_request transaction, token
    stub_request(:put, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/order\/#{transaction.order_id}\/transaction\/#{transaction.transaction_id}/).
      with :body => JSON.generate({
             'apiOperation' => 'PAY',
             'order'        => {'reference' => transaction.reference.to_s},
             'cardDetails'  => {'session' => token.to_s},
             'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction.transaction_id.to_s}
           }),
           :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '158',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_credit_card_token_purchase_request transaction, token
    stub_request(:put, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/order\/#{transaction.order_id}\/transaction\/#{transaction.transaction_id}/).
      with :body => JSON.generate({
             'apiOperation' => 'PAY',
             'order'        => {'reference' => transaction.reference.to_s},
             'cardDetails'  => {'cardToken' => token.to_s},
             'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction.transaction_id.to_s}
           }),
           :headers => {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '164',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_refund_request transaction
    stub_request(:put, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/order\/#{transaction.order_id}\/transaction\/#{transaction.transaction_id}/).
      with :body => JSON.generate({
             'apiOperation' => 'REFUND',
             'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency, 'reference' => transaction.transaction_id.to_s}
           }),
           :headers => {
             'Accept'          => '*/*',
             'Accept-Encoding' => 'gzip, deflate',
             'Content-Length'  => '89',
             'Content-Type'    => 'Application/json;charset=UTF-8'
           }
  end

  def stub_create_credit_card_token_request
    stub_request(:post, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/token/).
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'}, :body => {})
  end

  def stub_delete_credit_card_token_request
    stub_request(:delete, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/token\/\d{16}/).
      with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'Application/json;charset=UTF-8'}, :body => {})
  end

  def stub_successful_check_enrollment_request transaction, token
    stub_request(:put, /https:\/\/:#{@gateway.api_key}@secure\.ap\.tnspayments\.com\/api\/rest\/version\/4\/merchant\/#{@gateway.merchant_id}\/3DSecureId\/#{transaction.three_d_s_id}/).
      with(:body => JSON.generate({
           '3DSecure'     => {'authenticationRedirect' => {'pageGenerationMode' => 'CUSTOMIZED', 'responseUrl' => 'http://google.com/'}},
           'apiOperation' => 'CHECK_3DS_ENROLLMENT',
           'cardDetails'  => {'session' => token},
           'transaction'  => {'amount' => transaction.amount.to_s, 'currency' => transaction.currency}
         }),
         :headers => {
           'Accept'          => '*/*',
           'Accept-Encoding' => 'gzip, deflate',
           'Content-Length'  => '237',
           'Content-Type'    => 'Application/json;charset=UTF-8'
         }).
      to_return :status => 200, :headers => {}, :body => "{\"3DSecure\":{\"authenticationRedirect\":{\"customized\":{\"acsUrl\":\"https://secure.ap.tnspayments.com:443/acs/MastercardACS/4272b87b-2cc0-4232-a96e-e678ecbe7455\",\"paReq\":\"eAFVkd1ugkAQhe9NfAfCfV1ghVIzrNFq1aY/pNqY9I7AKCQCukILfZ2+SZ+sswq1vePMcGbPfAPDKt1p7yiPSZ55utkzdA2zMI+SbOvpr6u7K1cfim4HVrFEnCwxLCUKeMTjMdiilkSezrlpmJbh6gL80QseBDTjBE3rWcBaSS4ZxkFWCAjCw3jxJGyLG44NrJGQolxMhGnxvu1cu8DOGrIgRTGlMXUU1NocZa49FBGwUx3CvMwKWQvXcoC1Akq5E3FR7AeMITnJGJOvF+YpMNUDdknjlyrXkfaqkkg8R9HmrZotNx8pn8b17HNdGfexX64nfQ+Y+gOioEBhqa25aWsWH3BnYFPeUx2CVCUSs7GvfX8RA4MWPJdgr14anYWpGn8LQGwlwW9XaRVgtc8zpJEE8/cb2CX27VwhDQuCZ7f0bige7xOSpqGmJITJ5AYRbwQwZWXN3QjJ6axU+XfubucHAPGz0w==\"}},\"summaryStatus\":\"CARD_ENROLLED\",\"xid\":\"OddfZxGSfwm3EhyGzWx0JhPuWD4=\"},\"3DSecureId\":\"#{transaction.three_d_s_id}\",\"merchant\":\"#{@gateway.merchant_id}\",\"response\":{\"3DSecure\":{\"gatewayCode\":\"CARD_ENROLLED\"}}}"
  end

  def mock_transaction
    mock = MiniTest::Mock.new
    mock.expect :amount, 100
    mock.expect :currency, 'AUD'
    mock.expect :order_id, 10000000001
    mock.expect :transaction_id, 1
    mock.expect :reference, 'AUD123'
    mock
  end
end
