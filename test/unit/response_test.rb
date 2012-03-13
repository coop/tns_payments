require 'helper'

class TNSPayments::ResponseTest < MiniTest::Unit::TestCase
  def test_success_when_operating
    assert Response.new({:result => 'OPERATING'}.to_json).success?
  end

  def test_success_when_success
    assert Response.new({:result => 'SUCCESS'}.to_json).success?
  end

  def test_success_when_not_successful
    refute Response.new({:result => '404 RESOURCE NOT FOUND'}.to_json).success?
  end

  def test_message_when_error_request
    response = "{\"result\":\"400 BAD REQUEST\",\"response\":\"{\\\"error\\\":{\\\"cause\\\":\\\"INVALID_REQUEST\\\",\\\"explanation\\\":\\\"Privilege(s) [HOSTED_PAYMENT_FORM] required\\\"},\\\"result\\\":\\\"ERROR\\\"}\"}"
    assert_equal 'Privilege(s) [HOSTED_PAYMENT_FORM] required', Response.new(response).message
  end

  def test_message_when_success_request
    assert_equal 'Successful request', Response.new({:result => 'SUCCESS'}.to_json).message
  end
end
