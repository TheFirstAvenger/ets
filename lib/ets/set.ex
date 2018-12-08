defmodule Ets.Set do
  @moduledoc """
  Module for creating and interacting with :ets tables of the type `:set` and `:ordered_set`.

  Sets contain tuple records. One element of the tuple is the key of the tuple, and is
  specified when the Set is created with the `keypos: 1` option. If not specified, the default
  is 1. When a record is added to the table with `put`, it will overwrite an existing record
  with the same key. `put_new` will only put the record if a matching key doesn't already exist.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> Set.put!(set, {:a, :b, :c})
      iex> Set.lookup!(set, :a)
      {:a, :b, :c}

  """
  use Ets.Utils

  alias Ets.{
    Base,
    Set
  }

  @type t :: %__MODULE__{
          info: keyword(),
          ordered: boolean(),
          table: Ets.table_reference()
        }

  @type set_options :: [Ets.Base.option() | {:ordered, boolean()}]

  defstruct table: nil, info: nil, ordered: nil

  @doc """
  Creates new set module with the specified options.

  Possible options:

  * `name:` when specified, creates a named table with the specified name
  * `ordered:` when true, creates :ordered_set, false creates :set. Defaults to false.
  * `protection:` :private, :protected, :public
  * `heir:` :none | {heir_pid, heir_data}
  * `keypos:` integer
  * `read_concurrency:` boolean
  * `write_concurrency:` boolean
  * `compressed:` boolean

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true, keypos: 3, read_concurrency: true, compressed: false)
      iex> Set.info!(set)[:read_concurrency]
      true

      # Named :ets tables via the name keyword
      iex> {:ok, set} = Set.new(name: :my_ets_table)
      iex> Set.info!(set)[:name]
      :my_ets_table

  """
  @spec new(set_options) :: {:error, any()} | {:ok, Set.t()}
  def new(opts \\ []) when is_list(opts) do
    {opts, ordered} = take_opt(opts, :ordered, false)

    if is_boolean(ordered) do
      case Base.new_table(type(ordered), opts) do
        {:error, reason} -> {:error, reason}
        {:ok, {table, info}} -> {:ok, %Set{table: table, info: info, ordered: ordered}}
      end
    else
      {:error, {:invalid_option, ordered: ordered}}
    end
  end

  @doc """
  Same as `new/1` but unwraps or raises on error.
  """
  @spec new!(set_options) :: Set.t()
  def new!(opts \\ []), do: unwrap_or_raise(new(opts))

  defp type(true), do: :ordered_set
  defp type(false), do: :set

  @doc """
  Returns information on the set.

  Second parameter forces updated information from ets, default (false) uses in-struct cached information.
  Force should be used when requesting size and memory.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true, keypos: 3, read_concurrency: true, compressed: false)
      iex> {:ok, info} = Set.info(set)
      iex> info[:read_concurrency]
      true
      iex> {:ok, _} = Set.put(set, {:a, :b, :c})
      iex> {:ok, info} = Set.info(set)
      iex> info[:size]
      0
      iex> {:ok, info} = Set.info(set, true)
      iex> info[:size]
      1

  """
  @spec info(Set.t(), boolean()) :: {:ok, keyword()} | {:error, any()}
  def info(set, force_update \\ false)
  def info(%Set{table: table}, true), do: Base.info(table)
  def info(%Set{info: info}, false), do: {:ok, info}

  @doc """
  Same as `info/1` but unwraps or raises on error.
  """
  @spec info!(Set.t(), boolean()) :: keyword()
  def info!(%Set{} = set, force_update \\ false) when is_boolean(force_update),
    do: unwrap_or_raise(info(set, force_update))

  @doc """
  Puts record into table. Overwrites records for existing keys

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> {:ok, _} = Set.put(set, {:a, :b, :c})
      iex> {:ok, _} = Set.put(set, {:d, :e, :f})
      iex> {:ok, _} = Set.put(set, {:d, :e, :f})
      iex> Set.to_list(set)
      {:ok, [{:a, :b, :c}, {:d, :e, :f}]}

  """
  @spec put(Set.t(), tuple()) :: {:ok, Set.t()} | {:error, any()}
  def put(%Set{table: table} = set, record) when is_tuple(record),
    do: Base.insert(table, record, set)

  @doc """
  Same as `put/3` but unwraps or raises on error.
  """
  @spec put!(Set.t(), tuple()) :: Set.t()
  def put!(%Set{} = set, record) when is_tuple(record),
    do: unwrap_or_raise(put(set, record))

  @doc """
  Same as `insert/2` but returns error and doesn't insert if key already exists.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> {:ok, _} = Set.insert_new(set, {:a, :b, :c})
      iex> {:ok, _} = Set.insert_new(set, {:d, :e, :f})
      iex> Set.insert_new(set, {:d, :e, :f})
      {:error, :key_already_exists}

  """
  @spec insert_new(Set.t(), tuple()) :: {:ok, Set.t()} | {:error, any()}
  def insert_new(%Set{table: table} = set, record) when is_tuple(record),
    do: Base.insert_new(table, record, set)

  @doc """
  Same as `insert_new/2` but unwraps or raises on error.
  """
  @spec insert_new!(Set.t(), tuple()) :: Set.t()
  def insert_new!(%Set{} = set, record) when is_tuple(record),
    do: unwrap_or_raise(insert_new(set, record))

  @doc """
  Inserts multiple records in an [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.
  Overwrites records for existing keys.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> {:ok, _} = Set.insert_multi(set, [{:a, :b, :c}, {:d, :e, :f}, {:d, :e, :f}])
      iex> Set.to_list(set)
      {:ok, [{:a, :b, :c}, {:d, :e, :f}]}
  """
  @spec insert_multi(Set.t(), list(tuple())) :: {:ok, Set.t()} | {:error, any()}
  def insert_multi(%Set{table: table} = set, records) when is_list(records),
    do: Base.insert_multi(table, records, set)

  @doc """
  Same as `insert_multi/2` but unwraps or raises on error.
  """
  @spec insert_multi!(Set.t(), list(tuple())) :: Set.t()
  def insert_multi!(%Set{} = set, records) when is_list(records),
    do: unwrap_or_raise(insert_multi(set, records))

  @doc """
  Same as `insert_multi/2` but returns error and doesn't insert if one of the specified keys already exists.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> {:ok, _} = Set.insert_multi_new(set, [{:a, :b, :c}, {:d, :e, :f}, {:d, :e, :f}])
      iex> {:error, :key_already_exists} = Set.insert_multi_new(set, [{:a, :b, :c}, {:d, :e, :f}, {:d, :e, :f}])
      iex> Set.to_list(set)
      {:ok, [{:a, :b, :c}, {:d, :e, :f}]}
  """
  @spec insert_multi_new(Set.t(), list(tuple())) :: {:ok, Set.t()} | {:error, any()}
  def insert_multi_new(%Set{table: table} = set, records) when is_list(records),
    do: Base.insert_multi_new(table, records, set)

  @doc """
  Same as `insert_multi_new/2` but unwraps or raises on error.
  """
  @spec insert_multi_new!(Set.t(), list(tuple())) :: Set.t()
  def insert_multi_new!(%Set{} = set, records) when is_list(records),
    do: unwrap_or_raise(insert_multi_new(set, records))

  @doc """
  Returns record with specified key or nil if no record found.

  ## Examples

      iex> Set.new!()
      iex> |> Set.put!({:a, :b, :c})
      iex> |> Set.put!({:d, :e, :f})
      iex> |> Set.lookup(:d)
      {:ok, {:d, :e, :f}}

  """
  @spec lookup(Set.t(), any()) :: {:ok, tuple()} | {:error, any()}
  def lookup(%Set{table: table}, key) do
    case Base.lookup(table, key) do
      {:ok, []} -> {:ok, nil}
      {:ok, [x | []]} -> {:ok, x}
      {:ok, _} -> {:error, :invalid_set}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `lookup/2` but unwraps or raises on error.
  """
  @spec lookup!(Set.t(), any()) :: tuple()
  def lookup!(%Set{} = set, key), do: unwrap_or_raise(lookup(set, key))

  @doc """
  Returns records in the specified Set that match the specified pattern.

  For more information on the match pattern, see the [erlang documentation](http://erlang.org/doc/man/ets.html#match-2)

  ## Examples

      iex> Set.new!(ordered: true)
      iex> |> Set.insert_multi!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :i, :j}])
      iex> |> Set.match({:"$1", :b, :"$2", :_})
      {:ok, [[:a, :c], [:h, :i]]}

  """
  @spec match(Set.t(), Ets.match_pattern()) :: {:ok, [tuple()]} | {:error, any()}
  def match(%Set{table: table}, pattern) when is_atom(pattern) or is_tuple(pattern),
    do: Base.match(table, pattern)

  @doc """
  Same as `match/2` but unwraps or raises on error.
  """
  @spec match!(Set.t(), Ets.match_pattern()) :: [tuple()]
  def match!(%Set{} = set, pattern) when is_atom(pattern) or is_tuple(pattern),
    do: unwrap_or_raise(match(set, pattern))

  @doc """
  Same as `match/2` but limits number of results to the specified limit.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.insert_multi!(set, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
      iex> {:ok, {results, _continuation}} = Set.match(set, {:"$1", :b, :"$2", :_}, 2)
      iex> results
      [[:a, :c], [:e, :f]]

  """
  @spec match(Set.t(), Ets.match_pattern(), non_neg_integer()) ::
          {:ok, {[tuple()], any() | :end_of_table}} | {:error, any()}
  def match(%Set{table: table}, pattern, limit), do: Base.match(table, pattern, limit)

  @doc """
  Same as `match/3` but unwraps or raises on error.
  """
  @spec match!(Set.t(), Ets.match_pattern(), non_neg_integer()) ::
          {[tuple()], any() | :end_of_table}
  def match!(%Set{} = set, pattern, limit), do: unwrap_or_raise(match(set, pattern, limit))

  @doc """
  Matches next set of records from a match/3 or match/1 continuation.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.insert_multi!(set, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
      iex> {:ok, {results, continuation}} = Set.match(set, {:"$1", :b, :"$2", :_}, 2)
      iex> results
      [[:a, :c], [:e, :f]]
      iex> {:ok, {records2, continuation2}} = Set.match(continuation)
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
  Determines if specified key exists in specified set.

  ## Examples

      iex> set = Set.new!()
      iex> Set.has_key(set, :key)
      {:ok, false}
      iex> Set.put(set, {:key, :value})
      iex> Set.has_key(set, :key)
      {:ok, true}

  """
  @spec has_key(Set.t(), any()) :: {:ok, boolean()} | {:error, any()}
  def has_key(%Set{table: table}, key), do: Base.has_key(table, key)

  @doc """
  Same as `has_key/2` but unwraps or raises on error.
  """
  @spec has_key!(Set.t(), any()) :: boolean()
  def has_key!(set, key), do: unwrap_or_raise(has_key(set, key))

  @doc """
  Returns the first key in the specified Set. Set must be ordered or error is returned.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.first(set)
      {:error, :empty_table}
      iex> Set.put!(set, {:key1, :val})
      iex> Set.put!(set, {:key2, :val})
      iex> Set.first(set)
      {:ok, :key1}

  """
  @spec first(Set.t()) :: {:ok, any()} | {:error, any()}
  def first(%Set{ordered: false}), do: {:error, :set_not_ordered}
  def first(%Set{table: table}), do: Base.first(table)

  @doc """
  Same as `first/1` but unwraps or raises on error
  """
  @spec first!(Set.t()) :: any()
  def first!(%Set{} = set), do: unwrap_or_raise(first(set))

  @doc """
  Returns the last key in the specified Set. Set must be ordered or error is returned.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.last(set)
      {:error, :empty_table}
      iex> Set.put!(set, {:key1, :val})
      iex> Set.put!(set, {:key2, :val})
      iex> Set.last(set)
      {:ok, :key2}

  """
  @spec last(Set.t()) :: {:ok, any()} | {:error, any()}
  def last(%Set{ordered: false}), do: {:error, :set_not_ordered}
  def last(%Set{table: table}), do: Base.last(table)

  @doc """
  Same as `last/1` but unwraps or raises on error
  """
  @spec last!(Set.t()) :: any()
  def last!(set), do: unwrap_or_raise(last(set))

  @doc """
  Returns the next key in the specified Set.

  The given key does not need to exist in the set. The key returned will be the first key that exists in the
  set which is subsequent in term order to the key given.

  Set must be ordered or error is returned.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.put!(set, {:key1, :val})
      iex> Set.put!(set, {:key2, :val})
      iex> Set.put!(set, {:key3, :val})
      iex> Set.first(set)
      {:ok, :key1}
      iex> Set.next(set, :key1)
      {:ok, :key2}
      iex> Set.next(set, :key2)
      {:ok, :key3}
      iex> Set.next(set, :key3)
      {:error, :end_of_table}
      iex> Set.next(set, :a)
      {:ok, :key1}
      iex> Set.next(set, :z)
      {:error, :end_of_table}

  """
  @spec next(Set.t(), any()) :: {:ok, any()} | {:error, any()}
  def next(%Set{ordered: false}, _key), do: {:error, :set_not_ordered}
  def next(%Set{table: table}, key), do: Base.next(table, key)

  @doc """
  Same as `next/1` but unwraps or raises on error
  """
  @spec next!(Set.t(), any()) :: any()
  def next!(set, key), do: unwrap_or_raise(next(set, key))

  @doc """
  Returns the previous key in the specified Set.

  The given key does not need to exist in the set. The key returned will be the first key that exists in the
  set which is previous in term order to the key given.

  Set must be ordered or error is returned.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> Set.put!(set, {:key1, :val})
      iex> Set.put!(set, {:key2, :val})
      iex> Set.put!(set, {:key3, :val})
      iex> Set.last(set)
      {:ok, :key3}
      iex> Set.previous(set, :key3)
      {:ok, :key2}
      iex> Set.previous(set, :key2)
      {:ok, :key1}
      iex> Set.previous(set, :key1)
      {:error, :start_of_table}
      iex> Set.previous(set, :a)
      {:error, :start_of_table}
      iex> Set.previous(set, :z)
      {:ok, :key3}

  """
  @spec previous(Set.t(), any()) :: {:ok, any()} | {:error, any()}
  def previous(%Set{ordered: false}, _key), do: {:error, :set_not_ordered}

  def previous(%Set{table: table}, key), do: Base.previous(table, key)

  @doc """
  Same as `previous/1` but raises on :error

  Returns previous key in table.
  """
  @spec previous!(Set.t(), any()) :: any()
  def previous!(%Set{} = set, key), do: unwrap_or_raise(previous(set, key))

  @doc """
  Returns contents of table as a list.

  ## Examples

    iex> Set.new!(ordered: true)
    iex> |> Set.put!({:a, :b, :c})
    iex> |> Set.put!({:d, :e, :f})
    iex> |> Set.put!({:d, :e, :f})
    iex> |> Set.to_list()
    {:ok, [{:a, :b, :c}, {:d, :e, :f}]}

  """
  @spec to_list(Set.t()) :: {:ok, [tuple()]} | {:error, any()}
  def to_list(%Set{table: table}), do: Base.to_list(table)

  @doc """
  Same as `to_list/1` but unwraps or raises on error.
  """
  @spec to_list!(Set.t()) :: [tuple()]
  def to_list!(%Set{} = set), do: unwrap_or_raise(to_list(set))

  @doc """
  Deletes specified Set.

  ## Examples

      iex> {:ok, set} = Set.new()
      iex> {:ok, _} = Set.info(set, true)
      iex> {:ok, _} = Set.delete(set)
      iex> Set.info(set, true)
      {:error, :table_not_found}

  """
  @spec delete(Set.t()) :: {:ok, Set.t()} | {:error, any()}
  def delete(%Set{table: table} = set), do: Base.delete(table, set)

  @doc """
  Same as `delete/1` but unwraps or raises on error.
  """
  @spec delete!(Set.t()) :: Set.t()
  def delete!(%Set{} = set), do: unwrap_or_raise(delete(set))

  @doc """
  Deletes record with specified key in specified Set.

  ## Examples

      iex> set = Set.new!()
      iex> Set.put(set, {:a, :b, :c})
      iex> Set.delete(set, :a)
      iex> Set.lookup!(set, :a)
      nil

  """
  @spec delete(Set.t(), any()) :: {:ok, Set.t()} | {:error, any()}
  def delete(%Set{table: table} = set, key), do: Base.delete_records(table, key, set)

  @doc """
  Same as `delete/2` but unwraps or raises on error.
  """
  @spec delete!(Set.t(), any()) :: Set.t()
  def delete!(%Set{} = set, key), do: unwrap_or_raise(delete(set, key))

  @doc """
  Wraps an existing :ets :set or :ordered_set in a Set struct.

  ## Examples

      iex> :ets.new(:my_ets_table, [:set, :named_table])
      iex> {:ok, set} = Set.wrap_existing(:my_ets_table)
      iex> Set.info!(set)[:name]
      :my_ets_table

  """
  @spec wrap_existing(Ets.table_identifier()) :: {:ok, Set.t()} | {:error, any()}
  def wrap_existing(table_identifier) do
    case Base.wrap_existing(table_identifier, [:set, :ordered_set]) do
      {:ok, {table, info}} -> {:ok, %Set{table: table, info: info}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `wrap_existing/1` but unwraps or raises on error.
  """
  @spec wrap_existing!(Ets.table_identifier()) :: Set.t()
  def wrap_existing!(table_identifier), do: unwrap_or_raise(wrap_existing(table_identifier))
end
