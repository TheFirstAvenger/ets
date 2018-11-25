# Ets

`:ets`, the Elixir way

Ets is an Elixir wrapper for Erlang Term Storage (`:ets`). The purposes of this package is to improve the developer experience when both learning and interacting with Erlang Term Storage.

This will be accomplished by:

* Conforming to Elixir standards:
  * Data (on insert) and keys (on lookup) move to first parameter to support pipelines.
  * Two versions of all functions:
    * Main function (e.g. `lookup` returns `{:ok, return}`/`{:error, reason}` tuples.
    * Bang function (e.g. `lookup!`) returns value or raises on :error.
  * Inserted data is returned from insert calls to support pipelines.
  * All options specified via keyword list.
* Wrapping unhelpful `ArgumentError`'s with appropriate error returns.
* Wrapping `$end_of_table` in appropriate error returns/raises.
* Preventing insertion of `$end_of_table` where possible without affecting performance.
* Providing Elixir friendly documentation
* Providing two levels of abstraction, one addressing the most common cases (`Ets`), and the other addressing the advanced tuple record based cases (`Ets.Record`)
  * `Ets`
    * designed for most common case of inserting a single key/value pair in a `set`/`ordered_set` (with `insert!`). `bag`/`duplicate_bag` (which allow repeat keys) are also supported (with `insert_multi`)
    * designed for most common case of looking up a single value for a key in a `set`/`ordered_set` (with `lookup!`). `bag`/`duplicate_bag` (which allow repeat keys) are also supported (with `lookup_multi`)
    * `insert`/`insert_new` - takes a key and single value
    * `lookup` takes a key, returns a single value or `nil` (error if more than one found)
    * `insert_multi`/`insert_multi_new` - takes list of key/value pairs, or a list of values and a key, retains `atomic and isolated` nature of `:ets` multiple inserts.
    * `lookup_multi` takes a key, returns list of values found for key
  * `Ets.Record` advanced module for granting direct wrappers to `:ets` Tuple Record based functions.
    * `insert`/`insert_new` - takes a record tuple
    * `lookup!` - takes a key, returns record tuple or `nil` (raises if more than one found)
    * `insert_multi`/`insert_multi_new` - takes a list of record tuples, retains `atomic and isolated` nature of `:ets` multiple inserts.
    * `lookup_multi` takes a key, returns list of record tuples
    * Advanced features such as `match` and `select`

TODO:

* [X] `Ets`
  * [x] Insert
  * [x] Lookup
  * [X] Delete
  * [X] Delete All
  * [X] First
  * [X] Next
  * [X] Last
  * [X] Previous
  * [X] Has Key (Member)
* [X] `Ets.Table`
  * [X] Info
  * [X] All
  * [X] Delete
  * [X] TableToList
  * [X] Whereis
  * [X] Rename
  * [x] `Ets.Table.New`
* [X] `Ets.Record`
  * [X] Insert
  * [X] Lookup
  * [X] Match

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ets, "~> 0.1.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ets](https://hexdocs.pm/ets).

## Contributing

Contributions welcome. Specifically looking to:

* Add remainder of functions ([See Erlang Docs](http://erlang.org/doc/man/ets.html])).
* Discover and add zero-impact recovery for any additional possible `:ets` `ArgumentError`s.