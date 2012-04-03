require 'helper'

class TNSPayments::TransactionTest < MiniTest::Unit::TestCase
  def test_defaults_order_id_to_tns_minimum
    transaction = MiniTest::Mock.new
    transaction.expect :order_id, 0

    assert_equal 10000000000, Transaction.new(transaction).order_id
    assert transaction.verify
  end
end
