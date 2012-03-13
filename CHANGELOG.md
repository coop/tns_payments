# CHANGELOG

## 0.0.5 / (unreleased)

* Raise SessionTokenException when `session_token` request is invalid.

## 0.0.4 / 2012-03-08

* Check credit card token length as well as starting digit.
* Make `host` an accessor.
* Do not send an order reference when refunding.

## 0.0.3 / 2012-03-06

* `Connection#session_token` updates when the setter is called or when nil.

## 0.0.2 / 2012-03-05

* `Connection#purchase` and `Connection#refund` takes an object instead of many arguments.
* Allow passing in currency.

## 0.0.1 / 2012-02-24

* Initial release.