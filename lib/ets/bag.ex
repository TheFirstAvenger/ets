defmodule Ets.Bag do
  @moduledoc """
  Module for creating and interacting with :ets tables of the type `:bag` and `:duplicate_bag`.

  Bags contain "records" which are tuples. Bags are configured with a key position via the `keypos: integer` option.
  If not specified, the default key position is 1. The element of the tuple record at the key position is that records key.
  For example, setting the `keypos` to 2 means the key of an inserted record `{:a, :b}` is `:b`:

      iex> {:ok, bag} = Bag.new(keypos: 2)
      iex> Bag.add!(bag, {:a, :b})
      iex> Bag.lookup(bag, :a)
      {:ok, []}
      iex> Bag.lookup(bag, :b)
      {:ok, [{:a, :b}]}

  When a record is added to the table with `add_new` will only add the record if a matching key doesn't already exist.

  ## Examples

      iex> {:ok, bag} = Bag.new()
      iex> Bag.add_new!(bag, {:a, :b, :c})
      iex> Bag.to_list!(bag)
      [{:a, :b, :c}]
      iex> Bag.add_new!(bag, {:d, :e, :f})
      iex> Bag.to_list!(bag)
      [{:d, :e, :f}, {:a, :b, :c}]
      iex> Bag.add_new!(bag, {:a, :g, :h})
      iex> Bag.to_list!(bag)
      [{:d, :e, :f}, {:a, :b, :c}]

  `add` and `add_new` take either a single tuple or a list of tuple records. When adding multiple records,
  they are added in an atomic an isolated manner. `add_new` doesn't add any records if any of
  the new keys already exist in the bag.

  By default, Bags allow duplicate records (each element of the tuple record is identical). To prevent duplicate
  records, set the `duplicate: false` opt when creating the Bag (if you want to prevent duplicate *keys*, use an `Ets.Set`
  instead). Note that `duplicate: false` will increase the time it takes to add records as the table must be checked for
  duplicates prior to insert. `duplicate: true` maps to the `:ets` table type `:duplicate_bag`, `duplicate: false` maps to `:bag`.

  Bags implement [`Access`] _behaviour_.

  ## Examples

      iex> bag = Bag.new!(keypos: 2)
      iex> Bag.add!(bag, [{:a, :b, :c}, {:d, :e, :f}])
      iex> get_in(bag, [:b])
      [{:a, :c}]
      iex> get_in(bag, [:z])
      nil
      iex> with {[{:a, :c}], bag} <-
      ...>   pop_in(bag, [:b]), do: Bag.to_list!(bag)
      [{:d, :e, :f}]
      iex> with {nil, bag} <- pop_in(bag, [:z]), do: Bag.to_list!(bag)
      [{:d, :e, :f}]
      iex> with {[{:d, :f}], bag} <-
      ...>     get_and_update_in(bag, [:e], &{&1, [{:a, :b, :c}]}),
      ...>   do: Bag.to_list!(bag)
      [{:a, :b, :c}]

      iex> bag = Bag.new!()
      iex> Bag.add!(bag, [{:a, :b, :c}, {:a, :d, :e}, {:f, :g}, {:h}])
      iex> get_in(bag, [:a])
      [b: :c, d: :e]
  """

  use Ets.Utils
  use Ets.Access, find: :lookup, delete: :delete!, add: :add!

  alias Ets.{
    Bag,
    Base
  }

  @type t :: %__MODULE__{
          info: keyword(),
          duplicate: boolean(),
          table: Ets.table_reference()
        }

  @type bag_options :: [Ets.Base.option() | {:duplicate, boolean()}]

  defstruct table: nil, info: nil, duplicate: nil

  @doc """
  Creates new bag module with the specified options.

  Note that the underlying :ets table will be attached to the process that calls `new` and will be destroyed
  if that process dies.

  Possible options:

  * `name:` when specified, creates a named table with the specified name
  * `duplicate:` when true, allows multiple identical records. (default true)
  * `protection:` :private, :protected, :public (default :protected)
  * `heir:` :none | {heir_pid, heir_data} (default :none)
  * `keypos:` integer (default 1)
  * `read_concurrency:` boolean (default false)
  * `write_concurrency:` boolean (default false)
  * `compressed:` boolean (default false)

  ## Examples

      iex> {:ok, bag} = Bag.new(duplicate: false, keypos: 3, read_concurrency: true, compressed: false)
      iex> Bag.info!(bag)[:read_concurrency]
      true

      # Named :ets tables via the name keyword
      iex> {:ok, bag} = Bag.new(name: :my_ets_table)
      iex> Bag.info!(bag)[:name]
      :my_ets_table

  """
  @spec new(bag_options) :: {:error, any()} | {:ok, Bag.t()}
  def new(opts \\ []) when is_list(opts) do
    {opts, duplicate} = take_opt(opts, :duplicate, true)

    if is_boolean(duplicate) do
      case Base.new_table(type(duplicate), opts) do
        {:error, reason} -> {:error, reason}
        {:ok, {table, info}} -> {:ok, %Bag{table: table, info: info, duplicate: duplicate}}
      end
    else
      {:error, {:invalid_option, {:duplicate, duplicate}}}
    end
  end

  @doc """
  Same as `new/1` but unwraps or raises on error.
  """
  @spec new!(bag_options) :: Bag.t()
  def new!(opts \\ []), do: unwrap_or_raise(new(opts))

  defp type(true), do: :duplicate_bag
  defp type(false), do: :bag

  @doc """
  Returns information on the bag.

  Second parameter forces updated information from ets, default (false) uses in-struct cached information.
  Force should be used when requesting size and memory.

  ## Examples

      iex> {:ok, bag} = Bag.new(duplicate: false, keypos: 3, read_concurrency: true, compressed: false)
      iex> {:ok, info} = Bag.info(bag)
      iex> info[:read_concurrency]
      true
      iex> {:ok, _} = Bag.add(bag, {:a, :b, :c})
      iex> {:ok, info} = Bag.info(bag)
      iex> info[:size]
      0
      iex> {:ok, info} = Bag.info(bag, true)
      iex> info[:size]
      1

  """
  @spec info(Bag.t(), boolean()) :: {:ok, keyword()} | {:error, any()}
  def info(bag, force_update \\ false)
  def info(%Bag{table: table}, true), do: Base.info(table)
  def info(%Bag{info: info}, false), do: {:ok, info}

  @doc """
  Same as `info/1` but unwraps or raises on error.
  """
  @spec info!(Bag.t(), boolean()) :: keyword()
  def info!(%Bag{} = bag, force_update \\ false) when is_boolean(force_update),
    do: unwrap_or_raise(info(bag, force_update))

  @doc """
  Returns underlying `:ets` table reference.

  For use in functions that are not yet implemented. If you find yourself using this, please consider
  submitting a PR to add the necessary function to `Ets`.

  ## Examples

      iex> bag = Bag.new!(name: :my_ets_table)
      iex> {:ok, table} = Bag.get_table(bag)
      iex> info = :ets.info(table)
      iex> info[:name]
      :my_ets_table

  """
  @spec get_table(Bag.t()) :: {:ok, Ets.table_reference()}
  def get_table(%Bag{table: table}), do: {:ok, table}

  @doc """
  Same as `get_table/1` but unwraps or raises on error
  """
  @spec get_table!(Bag.t()) :: Ets.table_reference()
  def get_table!(%Bag{} = bag), do: unwrap(get_table(bag))

  @doc """
  Adds tuple record or list of tuple records to table.

  If Bag has `duplicate: false`, will overwrite duplicate records (full tuple must match, not just key).

  Inserts multiple records in an [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  ## Examples

      iex> {:ok, bag} = Bag.new()
      iex> {:ok, _} = Bag.add(bag, [{:a, :b, :c}, {:d, :e, :f}])
      iex> {:ok, _} = Bag.add(bag, {:a, :h, :i})
      iex> {:ok, _} = Bag.add(bag, {:d, :x, :y})
      iex> {:ok, _} = Bag.add(bag, {:d, :e, :f})
      iex> Bag.to_list(bag)
      {:ok, [{:d, :e, :f}, {:d, :x, :y}, {:d, :e, :f}, {:a, :b, :c}, {:a, :h, :i}]}

      iex> {:ok, bag} = Bag.new(duplicate: false)
      iex> {:ok, _} = Bag.add(bag, [{:a, :b, :c}, {:d, :e, :f}])
      iex> {:ok, _} = Bag.add(bag, {:a, :h, :i})
      iex> {:ok, _} = Bag.add(bag, {:d, :x, :y})
      iex> {:ok, _} = Bag.add(bag, {:d, :e, :f}) # won't insert due to duplicate: false
      iex> Bag.to_list(bag)
      {:ok, [{:d, :e, :f}, {:d, :x, :y}, {:a, :b, :c}, {:a, :h, :i}]}

  """
  @spec add(Bag.t(), tuple() | list(tuple())) :: {:ok, Bag.t()} | {:error, any()}
  def add(%Bag{table: table} = bag, record) when is_tuple(record),
    do: Base.insert(table, record, bag)

  def add(%Bag{table: table} = bag, records) when is_list(records),
    do: Base.insert_multi(table, records, bag)

  @doc """
  Same as `add/3` but unwraps or raises on error.
  """
  @spec add!(Bag.t(), tuple() | list(tuple())) :: Bag.t()
  def add!(%Bag{} = bag, record_or_records)
      when is_tuple(record_or_records) or is_list(record_or_records),
      do: unwrap_or_raise(add(bag, record_or_records))

  @doc """
  Same as `add/2` but doesn't add any records if one of the given keys already exists.

  ## Examples

      iex> bag = Bag.new!()
      iex> {:ok, _} = Bag.add_new(bag, [{:a, :b, :c}, {:d, :e, :f}])
      iex> {:ok, _} = Bag.add_new(bag, [{:a, :x, :y}, {:g, :h, :i}]) # skips due to duplicate :a key
      iex> {:ok, _} = Bag.add_new(bag, {:d, :z, :zz}) # skips due to duplicate :d key
      iex> Bag.to_list!(bag)
      [{:d, :e, :f}, {:a, :b, :c}]

  """
  @spec add_new(Bag.t(), tuple() | list(tuple())) :: {:ok, Bag.t()} | {:error, any()}
  def add_new(%Bag{table: table} = bag, record) when is_tuple(record),
    do: Base.insert_new(table, record, bag)

  def add_new(%Bag{table: table} = bag, records) when is_list(records),
    do: Base.insert_multi_new(table, records, bag)

  @doc """
  Same as `add_new/2` but unwraps or raises on error.
  """
  @spec add_new!(Bag.t(), tuple() | list(tuple())) :: Bag.t()
  def add_new!(%Bag{} = bag, record_or_records)
      when is_tuple(record_or_records) or is_list(record_or_records),
      do: unwrap_or_raise(add_new(bag, record_or_records))

  @doc """
  Returns list of records with specified key.

  ## Examples

      iex> Bag.new!()
      iex> |> Bag.add!({:a, :b, :c})
      iex> |> Bag.add!({:d, :e, :f})
      iex> |> Bag.add!({:d, :e, :g})
      iex> |> Bag.lookup(:d)
      {:ok, [{:d, :e, :f}, {:d, :e, :g}]}

  """
  @spec lookup(Bag.t(), any()) :: {:ok, [tuple()]} | {:error, any()}
  def lookup(%Bag{table: table}, key), do: Base.lookup(table, key)

  @doc """
  Same as `lookup/3` but unwraps or raises on error.
  """
  @spec lookup!(Bag.t(), any()) :: [tuple()]
  def lookup!(%Bag{} = bag, key), do: unwrap_or_raise(lookup(bag, key))

  @doc """
  Returns list of elements in specified position of records with specified key.

  ## Examples

      iex> Bag.new!()
      iex> |> Bag.add!({:a, :b, :c})
      iex> |> Bag.add!({:d, :e, :f})
      iex> |> Bag.add!({:d, :h, :i})
      iex> |> Bag.lookup_element(:d, 2)
      {:ok, [:e, :h]}

  """
  @spec lookup_element(Bag.t(), any(), non_neg_integer()) :: {:ok, [any()]} | {:error, any()}
  def lookup_element(%Bag{table: table}, key, pos), do: Base.lookup_element(table, key, pos)

  @doc """
  Same as `lookup_element/3` but unwraps or raises on error.
  """
  @spec lookup_element!(Bag.t(), any(), non_neg_integer()) :: [any()]
  def lookup_element!(%Bag{} = bag, key, pos), do: unwrap_or_raise(lookup_element(bag, key, pos))

  @doc """
  Returns records in the Bag that match the specified pattern.

  For more information on the match pattern, see the [erlang documentation](http://erlang.org/doc/man/ets.html#match-2)

  ## Examples

      iex> Bag.new!()
      iex> |> Bag.add!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :i, :j}])
      iex> |> Bag.match({:"$1", :b, :"$2", :_})
      {:ok, [[:h, :i], [:a, :c]]}

  """
  @spec match(Bag.t(), Ets.match_pattern()) :: {:ok, [tuple()]} | {:error, any()}
  def match(%Bag{table: table}, pattern) when is_atom(pattern) or is_tuple(pattern),
    do: Base.match(table, pattern)

  @doc """
  Same as `match/2` but unwraps or raises on error.
  """
  @spec match!(Bag.t(), Ets.match_pattern()) :: [tuple()]
  def match!(%Bag{} = bag, pattern) when is_atom(pattern) or is_tuple(pattern),
    do: unwrap_or_raise(match(bag, pattern))

  @doc """
  Same as `match/2` but limits number of results to the specified limit.

  ## Examples

      iex> bag = Bag.new!()
      iex> Bag.add!(bag, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
      iex> {:ok, {results, _continuation}} = Bag.match(bag, {:"$1", :b, :"$2", :_}, 2)
      iex> results
      [[:e, :f], [:a, :c]]

  """
  @spec match(Bag.t(), Ets.match_pattern(), non_neg_integer()) ::
          {:ok, {[tuple()], any() | :end_of_table}} | {:error, any()}
  def match(%Bag{table: table}, pattern, limit), do: Base.match(table, pattern, limit)

  @doc """
  Same as `match/3` but unwraps or raises on error.
  """
  @spec match!(Bag.t(), Ets.match_pattern(), non_neg_integer()) ::
          {[tuple()], any() | :end_of_table}
  def match!(%Bag{} = bag, pattern, limit), do: unwrap_or_raise(match(bag, pattern, limit))

  @doc """
  Matches next bag of records from a match/3 or match/1 continuation.

  ## Examples

      iex> bag = Bag.new!()
      iex> Bag.add!(bag, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
      iex> {:ok, {results, continuation}} = Bag.match(bag, {:"$1", :b, :"$2", :_}, 2)
      iex> results
      [[:e, :f], [:a, :c]]
      iex> {:ok, {records2, continuation2}} = Bag.match(continuation)
      iex> records2
      [[:h, :i]]
      iex> continuation2
      :end_of_table

  """
  @spec match(any()) :: {:ok, {[tuple()], any() | :end_of_table}} | {:error, any()}
  def match(continuation), do: Base.match(continuation)

  @doc """
  Same as `match/1` but unwraps or raises on error.
  """
  @spec match!(any()) :: {[tuple()], any() | :end_of_table}
  def match!(continuation), do: unwrap_or_raise(match(continuation))

  @doc """
  Returns records in the specified Bag that match the specified match specification.

  For more information on the match specification, see the [erlang documentation](http://erlang.org/doc/man/ets.html#select-2)

  ## Examples

      iex> Bag.new!()
      iex> |> Bag.add!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :i, :j}])
      iex> |> Bag.select([{{:"$1", :b, :"$2", :_},[],[:"$$"]}])
      {:ok, [[:h, :i], [:a, :c]]}

  """
  @spec select(Bag.t(), Ets.match_spec()) :: {:ok, [tuple()]} | {:error, any()}
  def select(%Bag{table: table}, spec) when is_list(spec),
    do: Base.select(table, spec)

  @doc """
  Same as `select/2` but unwraps or raises on error.
  """
  @spec select!(Bag.t(), Ets.match_spec()) :: [tuple()]
  def select!(%Bag{} = bag, spec) when is_list(spec),
    do: unwrap_or_raise(select(bag, spec))

  @doc """
  Deletes records in the specified Bag that match the specified match specification.

  For more information on the match specification, see the [erlang documentation](http://erlang.org/doc/man/ets.html#select_delete-2)

  ## Examples

      iex> bag = Bag.new!()
      iex> bag
      iex> |> Bag.add!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :c, :h}])
      iex> |> Bag.select_delete([{{:"$1", :b, :"$2", :_},[{:"==", :"$2", :c}],[true]}])
      {:ok, 2}
      iex> Bag.to_list!(bag)
      [{:e, :c, :f, :g}]

  """
  @spec select_delete(Bag.t(), Ets.match_spec()) :: {:ok, non_neg_integer()} | {:error, any()}
  def select_delete(%Bag{table: table}, spec) when is_list(spec),
    do: Base.select_delete(table, spec)

  @doc """
  Same as `select_delete/2` but unwraps or raises on error.
  """
  @spec select_delete!(Bag.t(), Ets.match_spec()) :: non_neg_integer()
  def select_delete!(%Bag{} = bag, spec) when is_list(spec),
    do: unwrap_or_raise(select_delete(bag, spec))

  @doc """
  Determines if specified key exists in specified bag.

  ## Examples

      iex> bag = Bag.new!()
      iex> Bag.has_key(bag, :key)
      {:ok, false}
      iex> Bag.add(bag, {:key, :value})
      iex> Bag.has_key(bag, :key)
      {:ok, true}

  """
  @spec has_key(Bag.t(), any()) :: {:ok, boolean()} | {:error, any()}
  def has_key(%Bag{table: table}, key), do: Base.has_key(table, key)

  @doc """
  Same as `has_key/2` but unwraps or raises on error.
  """
  @spec has_key!(Bag.t(), any()) :: boolean()
  def has_key!(bag, key), do: unwrap_or_raise(has_key(bag, key))

  @doc """
  Returns contents of table as a list.

  ## Examples

      iex> Bag.new!()
      iex> |> Bag.add!({:a, :b, :c})
      iex> |> Bag.add!({:d, :e, :f})
      iex> |> Bag.add!({:d, :e, :f})
      iex> |> Bag.to_list()
      {:ok, [{:d, :e, :f}, {:d, :e, :f}, {:a, :b, :c}]}

  """
  @spec to_list(Bag.t()) :: {:ok, [tuple()]} | {:error, any()}
  def to_list(%Bag{table: table}), do: Base.to_list(table)

  @doc """
  Same as `to_list/1` but unwraps or raises on error.
  """
  @spec to_list!(Bag.t()) :: [tuple()]
  def to_list!(%Bag{} = bag), do: unwrap_or_raise(to_list(bag))

  @doc """
  Deletes specified Bag.

  ## Examples

      iex> {:ok, bag} = Bag.new()
      iex> {:ok, _} = Bag.info(bag, true)
      iex> {:ok, _} = Bag.delete(bag)
      iex> Bag.info(bag, true)
      {:error, :table_not_found}

  """
  @spec delete(Bag.t()) :: {:ok, Bag.t()} | {:error, any()}
  def delete(%Bag{table: table} = bag), do: Base.delete(table, bag)

  @doc """
  Same as `delete/1` but unwraps or raises on error.
  """
  @spec delete!(Bag.t()) :: Bag.t()
  def delete!(%Bag{} = bag), do: unwrap_or_raise(delete(bag))

  @doc """
  Deletes record with specified key in specified Bag.

  ## Examples

      iex> bag = Bag.new!()
      iex> Bag.add(bag, {:a, :b, :c})
      iex> Bag.delete(bag, :a)
      iex> Bag.lookup!(bag, :a)
      []

  """
  @spec delete(Bag.t(), any()) :: {:ok, Bag.t()} | {:error, any()}
  def delete(%Bag{table: table} = bag, key), do: Base.delete_records(table, key, bag)

  @doc """
  Same as `delete/2` but unwraps or raises on error.
  """
  @spec delete!(Bag.t(), any()) :: Bag.t()
  def delete!(%Bag{} = bag, key), do: unwrap_or_raise(delete(bag, key))

  @doc """
  Deletes all records in specified Bag.

  ## Examples

      iex> bag = Bag.new!()
      iex> bag
      iex> |> Bag.add!({:a, :b, :c})
      iex> |> Bag.add!({:b, :b, :c})
      iex> |> Bag.add!({:c, :b, :c})
      iex> |> Bag.to_list!()
      [{:c, :b, :c}, {:b, :b, :c}, {:a, :b, :c}]
      iex> Bag.delete_all(bag)
      iex> Bag.to_list!(bag)
      []

  """
  @spec delete_all(Bag.t()) :: {:ok, Bag.t()} | {:error, any()}
  def delete_all(%Bag{table: table} = bag), do: Base.delete_all_records(table, bag)

  @doc """
  Same as `delete_all/1` but unwraps or raises on error.
  """
  @spec delete_all!(Bag.t()) :: Bag.t()
  def delete_all!(%Bag{} = bag), do: unwrap_or_raise(delete_all(bag))

  @doc """
  Wraps an existing :ets :bag or :duplicate_bag in a Bag struct.

  ## Examples

      iex> :ets.new(:my_ets_table, [:bag, :named_table])
      iex> {:ok, bag} = Bag.wrap_existing(:my_ets_table)
      iex> Bag.info!(bag)[:name]
      :my_ets_table

  """
  @spec wrap_existing(Ets.table_identifier()) :: {:ok, Bag.t()} | {:error, any()}
  def wrap_existing(table_identifier) do
    case Base.wrap_existing(table_identifier, [:bag, :duplicate_bag]) do
      {:ok, {table, info}} ->
        {:ok, %Bag{table: table, info: info, duplicate: info[:type] == :duplicate_bag}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `wrap_existing/1` but unwraps or raises on error.
  """
  @spec wrap_existing!(Ets.table_identifier()) :: Bag.t()
  def wrap_existing!(table_identifier), do: unwrap_or_raise(wrap_existing(table_identifier))
end
