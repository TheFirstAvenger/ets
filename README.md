# Ets

`:ets`, the Elixir way

Ets is an Elixir wrapper for Erlang Term Storage (`:ets`). The purposes of this package is to improve the developer experience when both learning and interacting with Erlang Term Storage.

This will be accomplished by:

* Conforming to Elixir standards
  * Data (on insert) and keys (on lookup) moves to first parameter to support pipelines
  * Data (on insert) is returned from insert calls to support pipelines
  * Keyword lists used for options
* Providing Elixir friendly documentation
* Two levels of abstraction, one addressing the most common cases, and the other addressing the advanced cases
  * `Ets`
    * designed for most common case of single key/value pairs in a `set`/`ordered_set` (with `lookup`). `bag`/`duplicate_bag` (which allow repeat keys) are also supported (with `lookup_multi`)
    * `insert` - takes a key and single value
    * `lookup!` takes a key, returns a single value or `nil` (raises if more than one found)
    * `insert_multi` - takes list of key/value pairs, retains `atomic and isolated` nature of `:ets` multiple inserts.
    * `lookup_multi` takes a key, returns list of values found for key
  * `Ets.T` (T for Tuple) module for advanced version granting direct wrappers to `:ets` tuple-based functions.
    * `insert` - takes a record tuple
    * `lookup!` - takes a key, returns record tuple or `nil` (raises if more than one found)
    * `insert_multi` - takes a list of record tuples, retains `atomic and isolated` nature of `:ets` multiple inserts.
    * `lookup_multi` takes a key, returns list of record tuples

TODO:

* [ ] `Ets`
  * [x] `Ets.New`
    * [ ] Tweaks Options
  * [x] Insert
  * [x] Lookup
  * [ ] Info
  * [ ] Delete
  * [ ] TableToList
  * [ ] All
  * [ ] First
* [ ] `Ets.T`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ets, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ets](https://hexdocs.pm/ets).

