require 'helper'

class TNSPayments::ResponseTest < MiniTest::Unit::TestCase
  def test_success_when_success
    assert Response.new({:result => 'SUCCESS'}.to_json).success?
  end

  def test_success_when_not_successful
    refute Response.new({:result => '404 RESOURCE NOT FOUND'}.to_json).success?
  end

  def test_message_when_error_request
    response = "{\"result\":\"401 UNAUTHORIZED\",\"error\":{\"cause\":\"INVALID_REQUEST\",\"explanation\":\"Invalid credentials.\"},\"result\":\"ERROR\"}"
    assert_equal 'Invalid credentials.', Response.new(response).message
  end

  def test_message_when_success_request
    assert_equal 'Successful request', Response.new({:result => 'SUCCESS', :response => {}}.to_json).message
  end

  def test_raw_response_is_the_json
    response = "{\"result\":\"401 UNAUTHORIZED\",\"response\":{\"error\":{\"cause\":\"INVALID_REQUEST\",\"explanation\":\"Invalid credentials.\"},\"result\":\"ERROR\"}}"
    assert_equal response, Response.new(response).raw_response
  end
end
