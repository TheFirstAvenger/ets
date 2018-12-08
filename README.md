# Ets

`:ets`, the Elixir way

Ets is a set of Elixir modules that wrap Erlang Term Storage (`:ets`). The purposes of this package is to improve the developer experience when both learning and interacting with Erlang Term Storage.

This will be accomplished by:

* Conforming to Elixir standards:
  * Two versions of all functions:
    * Main function (e.g. `lookup` returns `{:ok, return}`/`{:error, reason}` tuples.
    * Bang function (e.g. `lookup!`) returns value or raises on :error.
  * All options specified via keyword list.
* Providing Elixir friendly documentation
* Providng `Set` and `Bag` modules with appropriate function signatures and error handling
  * `Set.lookup` returns a single item or nil as duplicates are not allowed
* Wrapping unhelpful `ArgumentError`'s with appropriate error returns.
* Handle `$end_of_table`
  * Appropriate error returns/raises when encountered.
  * Prevent insertion of `$end_of_table` where possible without affecting performance.

## Usage

### Creating Tables

Tables can be created using the `set`, `ordered_set`, `bag`, and `duplicate_bag` functions on the [`Ets.Table.New`](lib/ets/table/new.ex) module (See module documentation for more examples and documentation).

#### Table Examples

    # Unnamed table creation return reference
    iex> {:ok, ref} = Ets.Table.New.bag()
    iex> is_reference(ref)
    true

    # Named Tables take a table name
    iex> Ets.Table.New.bag(:my_ets_table)
    {:ok, :my_ets_table}

    # All functions have a bang version that returns the unwrapped value or raises
    iex> ref = Ets.Table.New.bag!()
    iex> is_reference(ref)
    true

    # All functions take keyword lists for options
    iex> {:ok, ref} = Ets.Table.New.bag(protection: :public, read_concurrency: true)

### Table Level Functions

Table level functions can be accessed using the [`Ets.Table`](lib/ets/table.ex) module.

#### Table Level Function Examples

    # List all tables
    iex> Ets.Table.New.set(:my_ets_table)
    iex> {:ok, all} = Ets.Table.all()
    iex> Enum.member?(all, :my_ets_table)
    true

    # Delete a table
    iex> Ets.Table.New.set(:my_ets_table)
    iex> Enum.member?(Ets.Table.all!(), :my_ets_table)
    true
    iex> Ets.Table.delete!(:my_ets_table)
    :my_ets_table
    iex> Enum.member?(Ets.Table.all!(), :my_ets_table)
    false

    # Lookup table info
    iex> Ets.Table.New.set(:my_ets_table)
    iex> {:ok, info} = Ets.Table.info(:my_ets_table)
    iex> info[:type]
    :set
    iex> info[:named_table]
    true
    iex> info[:protection]
    :protected

    # Rename a table
    iex> Ets.Table.New.set(:my_ets_table)
    iex> ref = Ets.Table.info!(:my_ets_table)[:id]
    iex> Ets.Table.rename(:new_name, :my_ets_table)
    iex> ref == Ets.Table.info!(:new_name)[:id]
    true

    # Table to list (`:ets.tab2list`)
    iex> Ets.Table.New.bag(:my_ets_table)
    iex> Ets.insert_multi([:a, :b, :c], :my_ets_table, :key1)
    iex> Ets.insert_multi([:a, :b, :c], :my_ets_table, :key2)
    iex> Ets.Table.to_list(:my_ets_table)
    {:ok, [{:key2, :a}, {:key2, :b}, {:key2, :c}, {:key1, :a}, {:key1, :b}, {:key1, :c}]}

    # Whereis
    iex> Ets.Table.New.set(:my_ets_table)
    iex> {:ok, ref} = Ets.Table.whereis(:my_ets_table)
    iex> is_reference(ref)
    true

### Insert (`Ets`)

Insert takes values as the first paramter to support pipelines. Second parameter is the table name or reference. When required, key is the third parameter. More examples and documentation can be found on the [`Ets` module page](lib/ets.ex)

#### Insert Examples

    iex> Ets.insert(:a, :my_ets_table, :my_key)
    {:ok, :a}

    # Designed to be used in pipelines:
    iex> _inserted = "myVal"
    iex> |> String.to_atom()
    iex> |> Ets.insert(:my_ets_table, :my_key)
    {:ok, :myVal}

    # Insert multiple values for the same key
    iex> Ets.insert_multi([:val1, :val2], :my_ets_table, :key)
    {:ok, [:val1, :val2]}
    iex> Ets.Table.to_list(:my_ets_table)
    {:ok, [{:key, :val1}, {:key, :val2}]}

    # Insert multiple values for different keys
    iex> [{:key1, :val1}, {:key2, :val2}]
    iex> |> Ets.insert_multi(:my_ets_table)
    {:ok, [{:key1, :val1}, {:key2, :val2}]}

### Lookup (`Ets`)

Lookup takes a key and returns the found value or nil (useful for `set`/`ordered_set`). lookup_multi returns a list of found values (useful for `bag`/`duplicate_bag`) More examples and documentation can be found on the [`Ets` module page](lib/ets.ex)

#### Lookup Examples

    # Lookup single value (set/ordered_set)
    iex> Ets.lookup(:key, :my_ets_table)
    {:ok, nil}
    iex> Ets.insert(:a, :my_ets_table, :key)
    iex> Ets.lookup(:key, :my_ets_table)
    {:ok, :a}

    # Lookup (possibly) multiple values (bag/duplicate_bag)
    iex> Ets.insert(:a, :my_ets_table, :key)
    iex> Ets.insert(:b, :my_ets_table, :key)
    iex> Ets.insert(:c, :my_ets_table, :key)
    iex> Ets.lookup_multi(:key, :my_ets_table)
    {:ok, [:a, :b, :c]}

### Should I use `Ets` or `Ets.Record`

If you need a key/value store, where you store key/value pairs, and need to update/delete the values for given keys, you should use the `Ets` module with a `set`/`ordered_set` (if you only want one entry allowed per key), `bag` (if you want to allow duplicate keys) or `duplicate_bag` (if you want to allow duplicate key/value pairs). Note that `Ets` assumes the keypos is 1 (which is the default when creating a table), so do not specify a different keypos or `Ets` will not function correctly.

If you want to store tuple records (similar to the underlying `:ets` interface), and use advanced features such as matching against those records, you should use the `Ets.Record` module. This module includes the improvements mentioned above (such as wrapping raised errors in error returns and pipeline-friendly parameter order), but retains the underlying record-tuple based interface. Note that functions such as `delete`, `delete_all`, `first`, `next`, `previous`, `last`, and `has_key` are not implemented in `Ets.Record` because the base `Ets` module version of these work the same on record-tuple based tables.

Implemented so far:

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
    {:ets, "~> 0.1.2"}
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