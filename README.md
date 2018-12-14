# Ets

`:ets`, the Elixir way

[![Build Status](https://travis-ci.com/TheFirstAvenger/ets.svg?branch=master)](https://travis-ci.com/TheFirstAvenger/ets)
[![Coverage Status](https://coveralls.io/repos/github/TheFirstAvenger/ets/badge.svg?branch=master)](https://coveralls.io/github/TheFirstAvenger/ets?branch=master)
[![Project license](https://img.shields.io/hexpm/l/ets.svg)](https://unlicense.org/)
[![Hex.pm package](https://img.shields.io/hexpm/v/ets.svg)](https://hex.pm/packages/ets)
[![Hex.pm downloads](https://img.shields.io/hexpm/dt/ets.svg)](https://hex.pm/packages/ets)

Ets is a set of Elixir modules that wrap Erlang Term Storage (`:ets`). The purposes of this package is to improve the developer experience when both learning and interacting with Erlang Term Storage.

This will be accomplished by:

* Conforming to Elixir standards:
  * Two versions of all functions:
    * Main function (e.g. `get`) returns `{:ok, return}`/`{:error, reason}` tuples.
    * Bang function (e.g. `get!`) returns unwrapped value or raises on :error.
  * All options specified via keyword list.
* Wrapping unhelpful `ArgumentError`'s with appropriate error returns.
  * Avoid adding performance overhead by using try/rescue instead of pre-validation
  * On rescue, try to determine what went wrong (e.g. missing table) and return appropriate error
  * Fall back to `{:error, :unknown_error}` if unable to determine reason.
* Appropriate error returns/raises when encountering `$end_of_table`.
* Providing Elixir friendly documentation.
* Providing `Ets.Set` and `Ets.Bag` modules with appropriate function signatures and error handling.
  * `Ets.Set.get` returns a single item (or nil/provided default) instead of list as sets never have multiple records for a key.

## Changes

For a list of changes, see the [changelog](CHANGELOG.md)

## Usage

### Creating Ets Tables

Ets Tables can be created using the `new` function of the appropriate module, either `Ets.Set` (for ordered and unordered sets) or `Ets.Bag` (for duplicate or non-duplicate bags) (`Ets.Bag` coming soon). See module documentation for more examples and documentation.

#### Create Examples

    iex> {:ok, set} = Set.new(ordered: true, keypos: 3, read_concurrency: true, compressed: false)
    iex> Set.info!(set)[:read_concurrency]
    true

    # Named :ets tables via the name keyword
    iex> {:ok, set} = Set.new(name: :my_ets_table)
    iex> Set.info!(set)[:name]
    :my_ets_table

### Adding/Updating/Retrieving records

To add records to an Ets table, use `put` or `put_new` with a tuple record or a list of tuple records.
`put` will overwrite existing records with the same key. `put_new` not insert if the key
already exists. When passing a list of tuple records, all records are inserted in an atomic and
isolated manner, but with `put_new` no records are inserted if at least one existing key is found.

#### Record Examples

    iex> Set.new(ordered: true)
    iex> |> Set.put!({:a, :b})
    iex> |> Set.put!({:a, :c})
    iex> |> Set.put!({:c, :d})
    iex> |> Set.to_list!()
    [{:a, :c}, {:c, :d}]

    iex> Set.new(ordered: true)
    iex> |> Set.put!({:a, :b})
    iex> |> Set.put({:a, :c})
    iex> |> Set.to_list!()
    [{:a, :b}]

## Current Progress

* [X] `Ets`
  * [X] All
* [X] `Ets.Set`
  * [x] Put (insert)
  * [x] Get (lookup)
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
  * [X] To List (tab2list)
  * [X] Wrap
* [ ] `Ets.Bag`

## Installation

`Ets` can be installed by adding `ets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ets, "~> 0.3.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/ets](https://hexdocs.pm/ets).

## Contributing

Contributions welcome. Specifically looking to:

* Add remainder of functions ([See Erlang Docs](http://erlang.org/doc/man/ets.html])).
* Discover and add zero-impact recovery for any additional possible `:ets` `ArgumentError`s.
