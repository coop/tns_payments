require 'helper'
require 'ostruct'
require 'digest'
require 'tns_payments/test_support/card_session'

class TNSPayments::OperationsTest < MiniTest::Unit::TestCase
  def test_available
    with_cassette do
      assert tns.available?
    end
  end

  def test_mastercard_successful_purchase
    order_id = 1

    with_cassette do
      session = TestSupport::CardSession.sample(:mastercard, tns)
      transaction = create_transaction(order_id)
      result = tns.purchase(transaction, session)
      response = result.response

      assert result.success?
      assert_equal 'CAPTURED', response['order']['status']
      assert_equal 'MASTERCARD', response['sourceOfFunds']['provided']['card']['brand']
    end
  end

  def test_visa_successful_purchase
    order_id = 2

    with_cassette do
      session = TestSupport::CardSession.sample(:visa, tns)
      transaction = create_transaction(order_id)
      result = tns.purchase(transaction, session)
      response = result.response

      assert result.success?
      assert_equal 'CAPTURED', response['order']['status']
      assert_equal 'VISA', response['sourceOfFunds']['provided']['card']['brand']
    end
  end

  def test_amex_successful_purchase
    order_id = 3

    with_cassette do
      session = TestSupport::CardSession.sample(:amex, tns)
      transaction = create_transaction(order_id)
      result = tns.purchase(transaction, session)
      response = result.response

      assert result.success?
      assert_equal 'CAPTURED', response['order']['status']
      assert_equal 'AMEX', response['sourceOfFunds']['provided']['card']['brand']
    end
  end

  def test_unsuccessful_purchase
    order_id = 10

    with_cassette do
      transaction = create_transaction(order_id)
      result = tns.purchase(transaction, "LOLSESSIONTOKEN")
      response = result.response

      refute result.success?
    end
  end

  def test_refund_successful_purchase
    order_id = 4

    with_cassette do
      session = TestSupport::CardSession.sample(:visa, tns)
      payment_transaction = create_transaction(order_id)
      result = tns.purchase(payment_transaction, session)
      response = result.response
      assert result.success?

      refund_transaction = create_refund_transaction(order_id)
      result = tns.refund(refund_transaction)
      response = result.response
      assert result.success?
    end
  end

  def test_tokenise_creditcard_from_session_for_later_purchase
    order_id = 5

    with_cassette do
      session = TestSupport::CardSession.sample(:visa, tns)
      result = tns.create_credit_card_token(session)
      response = result.response

      assert result.success?
      token = response['token']
      refute_nil token

      transaction = create_transaction(order_id)
      assert tns.purchase(transaction, token).success?
    end
  end

  def test_deleting_tokenised_card
    successful_order_id = 6
    failed_order_id = 7
    successful_transaction = create_transaction(successful_order_id)
    failed_transaction = create_transaction(failed_order_id)

    with_cassette do
      session = TestSupport::CardSession.sample(:visa, tns)
      token = tns.create_credit_card_token(session).response['token']

      assert tns.purchase(successful_transaction, token).success?
      assert tns.delete_credit_card_token(token).success?
      refute tns.purchase(failed_transaction, token).success?
    end
  end

  def test_card_enrolled_for_3ds
    order_id = 8

    with_3ds_enabled_tns do |tns|
      with_cassette do
        session = TestSupport::CardSession.sample(:visa_enrolled_3ds, tns)
        transaction = create_transaction(order_id, :currency => "GBP")

        result = tns.check_enrollment(transaction, session, "http://google.com")
        assert result.success?
        assert_equal 'CARD_ENROLLED', result.response['3DSecure']['summaryStatus']
      end
    end
  end

  def test_card_not_enrolled_for_3ds
    order_id = 9

    with_3ds_enabled_tns do |tns|
      with_cassette do
        session = TestSupport::CardSession.sample(:visa_not_enrolled_3ds, tns)
        transaction = create_transaction(order_id, :currency => "GBP")

        result = tns.check_enrollment(transaction, session, "http://google.com")
        assert result.success?
        assert_equal 'CARD_NOT_ENROLLED', result.response['3DSecure']['summaryStatus']
      end
    end
  end

  def test_unsupported_3ds_gateway
    order_id = 10

    with_3ds_disabled_tns do |tns|
      with_cassette do
        session = TestSupport::CardSession.sample(:visa_not_enrolled_3ds, tns)
        transaction = create_transaction(order_id, :currency => "EUR")

        result = tns.check_enrollment(transaction, session, "http://google.com")
        refute result.success?
      end
    end
  end

  private

  def create_transaction(order_id, options = {})
    transaction_id = options.fetch(:transaction_id) { "PAY" }
    currency = options.fetch(:currency) { "EUR" }

    OpenStruct.new(
      :amount => "100.00",
      :currency => currency,
      :order_id => prefix(order_id),
      :transaction_id => transaction_id,
      :reference => "PAY",
      :three_domain_id => Digest::SHA1.hexdigest(prefix(order_id).to_s)
    )
  end

  def create_refund_transaction(order_id)
    create_transaction(order_id, :transaction_id => "REFUND")
  end

  def prefix(order_id)
    1_700 + order_id
  end
end
