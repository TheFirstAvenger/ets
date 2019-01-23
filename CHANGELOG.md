# Changelog

## 0.6.0

* Add `Ets.Set.KeyValueSet`

## 0.5.0

* Handle and return `:table_already_exists` on `new`
* Fix spec for `Set.get` to reflect possible nil return
* Implemented `delete_all` for `Set` and `Bag`
* Implemented `select` for `Set` and `Bag`
* Implemented `select_delete` for `Set` and `Bag`
* Implemented `get_element`/`lookup_element` for `Set` and `Bag`
* Added `Bag`s to `Ets.all`
* Added list default option values in `new` documentation

## 0.4.0

* Implement `Ets.Bag`

## 0.3.0

* Combined `put_multi` into `put` and `put_multi_new` into `put_new`
* `put_new` with existing key(s) is no longer an error condition
* Catch list of non-tuples passed to `put` or `put_new`

## 0.2.2

* Fix issue with docs

## 0.2.1

* Add `get_table` to access underlying ets table reference (to directly access not-yet-implemented functions of `:ets`)

## 0.2.0

* Redesign from ground up to use module/struct based approach
* Implemented `Ets.Set` and `Ets.Base`
* Set up CI and Readme badges