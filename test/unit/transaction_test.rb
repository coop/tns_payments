require 'helper'

class TNSPayments::TransactionTest < MiniTest::Unit::TestCase
  def test_order_id_is_tns_minimum
    transaction = MiniTest::Mock.new
    transaction.expect :order_id, 0

    assert_equal 10000000000, Transaction.new(transaction).order_id
    assert transaction.verify
  end

  def test_minimum_order_id_is_injectable
    mock = MiniTest::Mock.new
    mock.expect :order_id, 10
    transaction = Transaction.new mock
    transaction.minimum_order_id = 0

    assert_equal 10, transaction.order_id
    assert mock.verify
  end
end
