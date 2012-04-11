require 'helper'

class TNSPayments::ErrorResponseTest < MiniTest::Unit::TestCase
  def test_cause_exists
    json = JSON.generate({'error' => {'cause' => 'foo'}})
    assert_equal 'foo', TNSPayments::ErrorResponse.new(json).cause
  end

  def test_invalid_request_is_true
    json = JSON.generate({'error' => {'cause' => 'INVALID_REQUEST'}})
    assert TNSPayments::ErrorResponse.new(json).invalid_request?
  end

  def test_invalid_request_is_false
    json = JSON.generate({'error' => {'cause' => 'SERVER_BUSY'}})
    refute TNSPayments::ErrorResponse.new(json).invalid_request?
  end

  def test_server_busy_is_true
    json = JSON.generate({'error' => {'cause' => 'SERVER_BUSY'}})
    assert TNSPayments::ErrorResponse.new(json).server_busy?
  end

  def test_server_busy_is_false
    json = JSON.generate({'error' => {'cause' => 'INVALID_REQUEST'}})
    refute TNSPayments::ErrorResponse.new(json).server_busy?
  end

  def test_request_rejected_is_true
    json = JSON.generate({'error' => {'cause' => 'REQUEST_REJECTED'}})
    assert TNSPayments::ErrorResponse.new(json).request_rejected?
  end

  def test_request_rejected_is_false
    json = JSON.generate({'error' => {'cause' => 'SERVER_BUSY'}})
    refute TNSPayments::ErrorResponse.new(json).request_rejected?
  end

  def test_server_failed_is_true
    json = JSON.generate({'error' => {'cause' => 'SERVER_FAILED'}})
    assert TNSPayments::ErrorResponse.new(json).server_failed?
  end

  def test_server_failed_is_false
    json = JSON.generate({'error' => {'cause' => 'REQUEST_REJECTED'}})
    refute TNSPayments::ErrorResponse.new(json).server_failed?
  end

  def test_explanation_when_invalid_request
    json = JSON.generate({'error' => {'cause' => 'INVALID_REQUEST', 'explanation' => 'Damn'}})
    assert_equal 'Damn', TNSPayments::ErrorResponse.new(json).explanation
  end

  def test_explanation_when_server_busy
    json = JSON.generate({'error' => {'cause' => 'SERVER_BUSY', 'explanation' => 'Damn'}})
    assert_equal 'Damn', TNSPayments::ErrorResponse.new(json).explanation
  end

  def test_explanation_when_anything_else
    json = JSON.generate({'error' => {'cause' => 'SERVER_FAILED', 'explanation' => 'Damn'}})
    assert_equal 'No explanation available for SERVER_FAILED', TNSPayments::ErrorResponse.new(json).explanation
  end

  def test_field_when_invalid_request
    json = JSON.generate({'error' => {'cause' => 'INVALID_REQUEST', 'field' => 'foo'}})
    assert_equal 'foo', TNSPayments::ErrorResponse.new(json).field
  end

  def test_field_when_anything_else
    json = JSON.generate({'error' => {'cause' => 'SERVER_FAILED', 'field' => 'foo'}})
    assert_nil TNSPayments::ErrorResponse.new(json).field
  end

  def test_support_code_when_server_failed
    json = JSON.generate({'error' => {'cause' => 'SERVER_FAILED', 'supportCode' => 'foo'}})
    assert_equal 'foo', TNSPayments::ErrorResponse.new(json).support_code
  end

  def test_support_code_when_request_rejected
    json = JSON.generate({'error' => {'cause' => 'REQUEST_REJECTED', 'supportCode' => 'foo'}})
    assert_equal 'foo', TNSPayments::ErrorResponse.new(json).support_code
  end

  def test_support_code_when_anything_else
    json = JSON.generate({'error' => {'cause' => 'INVALID_REQUEST', 'supportCode' => 'foo'}})
    assert_equal 'No support code for INVALID_REQUEST', TNSPayments::ErrorResponse.new(json).support_code
  end

  def test_success_is_false
    refute TNSPayments::ErrorResponse.new('{}').success?
  end

  def test_result
    json = JSON.generate({'result' => 'ERROR'})
    assert_equal 'ERROR', TNSPayments::ErrorResponse.new(json).result
  end
end
