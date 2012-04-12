# CHANGELOG

## 0.0.9 / 2012-04-12

* Error Responses get their own class in an attempt to provide consistency.
* Added TomDoc documentation.
* Separated concerns in Request class.

## 0.0.8 / 2012-04-11

* Default open_timeout and read_timeout to something sensible.
* Refactored order_id minimum into separate class.

## 0.0.7 / 2012-04-03

* Set order_id to 10000000000 plus the passed order_id.

## 0.0.6 / 2012-04-02

* 3D Secure

## 0.0.5 / 2012-03-29

* Tokenize credit card.
* Request gets it's own class.
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