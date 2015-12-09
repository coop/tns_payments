# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tns_payments/version"

Gem::Specification.new do |s|
  s.name        = "tns_payments"
  s.version     = TNSPayments::VERSION
  s.authors     = ["Tim Cooper"]
  s.email       = ["coop@latrobest.com"]
  s.homepage    = ""
  s.summary     = %q{Integration with TNS Payments Gateway}
  s.description = %q{Integration with TNS Payments Gateway}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency     'json', '1.4.6'
  s.add_runtime_dependency     'rest-client', '1.6.7'
  s.add_runtime_dependency     'mime-types', '1.16'
  s.add_runtime_dependency     'nokogiri', '1.2'
  s.add_development_dependency 'minitest', '2.11.4'
  s.add_development_dependency 'rake', '0.8.7'
  s.add_development_dependency 'webmock', '1.8.7'
  s.add_development_dependency 'addressable', '2.2.8'
end
