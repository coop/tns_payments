# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tns_payments/version"

Gem::Specification.new do |s|
  s.name        = "tns_payments"
  s.version     = TNSPayments::VERSION
  s.authors     = ["Tim Cooper"]
  s.email       = ["coop@latrobest.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Integration with TNS Payments Gateway}
  s.description = %q{TODO: Integration with TNS Payments Gateway}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency     'json'
  s.add_runtime_dependency     'rest-client'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'webmock'
end
