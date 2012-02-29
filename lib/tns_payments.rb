require 'tns_payments/connection'
require 'tns_payments/credit_card'
require 'tns_payments/response'
require 'tns_payments/version'

module TNSPayments
  def self.new options = {}
    Connection.new options
  end
end