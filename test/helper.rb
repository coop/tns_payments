require 'minitest/autorun'
require 'tns_payments'

include TNSPayments

require 'dotenv'
Dotenv.load

require 'webmock/minitest'

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'test/cassettes'
  config.hook_into :webmock
  config.default_cassette_options = {
    :match_requests_on => [:method, :uri, :body, :host],
    :record => :once,
  }
  ENV.keys.grep(/TNS_(3DS_)?(MERCHANT_ID|API_KEY)/).each do |key|
    config.filter_sensitive_data("<#{key}>") { ENV.fetch(key) }
  end
end

def tns
  @tns ||= TNSPayments.new(
    :merchant_id => ENV.fetch("TNS_MERCHANT_ID"),
    :api_key => ENV.fetch("TNS_API_KEY")
  )
end

def tns_3ds
  @tns_3ds ||= TNSPayments.new(
    :merchant_id => ENV.fetch("TNS_3DS_MERCHANT_ID"),
    :api_key => ENV.fetch("TNS_3DS_API_KEY")
  )
end

def with_3ds_enabled_tns
  yield(tns_3ds)
end

def with_3ds_disabled_tns
  yield(tns)
end

def with_cassette
  caller[0] =~ /`([^']*)'/

  VCR.use_cassette($1.to_s) do
    yield
  end
end
