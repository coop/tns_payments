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
end
