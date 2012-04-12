require 'tns_payments/connection'
require 'tns_payments/request'
require 'tns_payments/response'
require 'tns_payments/error_response'
require 'tns_payments/transaction'
require 'tns_payments/version'

module TNSPayments
  class SessionTokenException < Exception; end

  # Public: A proxy method to Connection.new.
  #
  # Returns a new Connection.
  def self.new options = {}
    Connection.new options
  end
end
