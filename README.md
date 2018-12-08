# Ets

`:ets`, the Elixir way

[![Build Status](https://semaphoreci.com/api/v1/thefirstavenger/ets/branches/master/badge.svg)](https://semaphoreci.com/thefirstavenger/ets)

Ets is a set of Elixir modules that wrap Erlang Term Storage (`:ets`). The purposes of this package is to improve the developer experience when both learning and interacting with Erlang Term Storage.

This will be accomplished by:

* Conforming to Elixir standards:
  * Two versions of all functions:
    * Main function (e.g. `get` returns `{:ok, return}`/`{:error, reason}` tuples.
    * Bang function (e.g. `get!`) returns value or raises on :error.
  * All options specified via keyword list.
* Providing Elixir friendly documentation
* Providng `Set` and `Bag` modules with appropriate function signatures and error handling
  * `Set.get` returns a single item or nil (instead of list) as duplicates are not allowed
* Wrapping unhelpful `ArgumentError`'s with appropriate error returns.
* Handle `$end_of_table`
  * Appropriate error returns/raises when encountered.
  * Prevent insertion of `$end_of_table` where possible without affecting performance.

## Usage

### Creating Tables

Tables can be created using the `new` function of the appropriate module, either `Ets.Set` (for ordered and unordered sets) or `Ets.Bag` (for duplicate or non-duplicate bags) (`Ets.Bag` coming soon). See module documentation for more examples and documentation.

* [X] `Ets`
  * [X] All
* [X] `Ets.Set`
  * [x] Insert (put)
  * [x] Lookup (get)
  * [X] Delete
  * [X] Delete All
  * [X] First
  * [X] Next
  * [X] Last
  * [X] Previous
  * [X] Match
  * [X] Has Key (Member)
  * [X] Info
  * [X] Delete
  * [X] TableToList (to_list)
  * [X] Wrap
* [ ] `Ets.Bag`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ets, "~> 0.2.0"}
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
