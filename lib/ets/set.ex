defmodule Ets.Set do
  @moduledoc """
  Module for creating and interacting with :ets tables of the type `:set` and `:ordered_set`.

  Sets contain "records" which are tuples. Sets are configured with a key position via the `keypos: integer` option.
  If not specified, the default key position is 1. The element of the tuple record at the key position is that records key.
  For example, setting the `keypos` to 2 means the key of an inserted record `{:a, :b}` is `:b`:

      iex> {:ok, set} = Set.new(keypos: 2)
      iex> Set.put!(set, {:a, :b})
      iex> Set.get(set, :a)
      {:ok, nil}
      iex> Set.get(set, :b)
      {:ok, {:a, :b}}

  When a record is added to the table with `put`, it will overwrite an existing record
  with the same key. `put_new` will only put the record if a matching key doesn't already exist.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> Set.put_new!(set, {:a, :b, :c})
      iex> Set.to_list!(set)
      [{:a, :b, :c}]
      iex> Set.put_new!(set, {:d, :e, :f})
      iex> Set.to_list!(set)
      [{:a, :b, :c}, {:d, :e, :f}]
      iex> Set.put_new!(set, {:a, :g, :h})
      iex> Set.to_list!(set)
      [{:a, :b, :c}, {:d, :e, :f}]

  `put` and `put_new` take either a single tuple or a list of tuples. When inserting multiple records,
  they are inserted in an atomic an isolated manner. `put_new` doesn't insert any records if any of
  the new keys already exist in the set.

  To make your set ordered (which maps to the `:ets` table type `:ordered_set`), specify `ordered: true`
  in the options list. An ordered set will store records in term order of the key of the record. This is
  helpful when using things like `first`, `last`, `previous`, `next`, and `to_list`, but comes with the penalty of
  log(n) insert time vs consistent insert time of an unordered set.

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

  Note that the underlying :ets table will be attached to the process that calls `new` and will be destroyed
  if that process dies.

  Possible options:

  * `name:` when specified, creates a named table with the specified name
  * `ordered:` when true, records in set are ordered (default false)
  * `protection:` :private, :protected, :public (default :protected)
  * `heir:` :none | {heir_pid, heir_data} (default :none)
  * `keypos:` integer (default 1)
  * `read_concurrency:` boolean (default false)
  * `write_concurrency:` boolean (default false)
  * `compressed:` boolean (default false)

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
      {:error, {:invalid_option, {:ordered, ordered}}}
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
  Returns underlying `:ets` table reference.

  For use in functions that are not yet implemented. If you find yourself using this, please consider
  submitting a PR to add the necessary function to `Ets`.

  ## Examples

      iex> set = Set.new!(name: :my_ets_table)
      iex> {:ok, table} = Set.get_table(set)
      iex> info = :ets.info(table)
      iex> info[:name]
      :my_ets_table

  """
  @spec get_table(Set.t()) :: {:ok, Ets.ets_table_reference()}
  def get_table(%Set{table: table}), do: {:ok, table}

  @doc """
  Same as `get_table/1` but unwraps or raises on error
  """
  @spec get_table!(Set.t()) :: Ets.ets_table_reference()
  def get_table!(%Set{} = set), do: unwrap_or_raise(get_table(set))

  @doc """
  Puts tuple record or list of tuple records into table. Overwrites records for existing key(s).

  Inserts multiple records in an [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  ## Examples

      iex> {:ok, set} = Set.new(ordered: true)
      iex> {:ok, _} = Set.put(set, [{:a, :b, :c}, {:d, :e, :f}])
      iex> {:ok, _} = Set.put(set, {:g, :h, :i})
      iex> {:ok, _} = Set.put(set, {:d, :x, :y})
      iex> Set.to_list(set)
      {:ok, [{:a, :b, :c}, {:d, :x, :y}, {:g, :h, :i}]}

  """
  @spec put(Set.t(), tuple() | list(tuple())) :: {:ok, Set.t()} | {:error, any()}
  def put(%Set{table: table} = set, record) when is_tuple(record),
    do: Base.insert(table, record, set)

  def put(%Set{table: table} = set, records) when is_list(records),
    do: Base.insert_multi(table, records, set)

  @doc """
  Same as `put/2` but unwraps or raises on error.
  """
  @spec put!(Set.t(), tuple() | list(tuple())) :: Set.t()
  def put!(%Set{} = set, record_or_records)
      when is_tuple(record_or_records) or is_list(record_or_records),
      do: unwrap_or_raise(put(set, record_or_records))

  @doc """
  Same as `put/2` but doesn't put any records if one of the given keys already exists.

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> {:ok, _} = Set.put_new(set, [{:a, :b, :c}, {:d, :e, :f}])
      iex> {:ok, _} = Set.put_new(set, [{:a, :x, :y}, {:g, :h, :i}]) # skips due to duplicate :a key
      iex> {:ok, _} = Set.put_new(set, {:d, :z, :zz}) # skips due to duplicate :d key
      iex> Set.to_list!(set)
      [{:a, :b, :c}, {:d, :e, :f}]

  """
  @spec put_new(Set.t(), tuple() | list(tuple())) :: {:ok, Set.t()} | {:error, any()}
  def put_new(%Set{table: table} = set, record) when is_tuple(record),
    do: Base.insert_new(table, record, set)

  def put_new(%Set{table: table} = set, records) when is_list(records),
    do: Base.insert_multi_new(table, records, set)

  @doc """
  Same as `put_new/2` but unwraps or raises on error.
  """
  @spec put_new!(Set.t(), tuple() | list(tuple())) :: Set.t()
  def put_new!(%Set{} = set, record_or_records)
      when is_tuple(record_or_records) or is_list(record_or_records),
      do: unwrap_or_raise(put_new(set, record_or_records))

  @doc """
  Returns record with specified key or the provided default (nil if not specified) if no record found.

  ## Examples

      iex> Set.new!()
      iex> |> Set.put!({:a, :b, :c})
      iex> |> Set.put!({:d, :e, :f})
      iex> |> Set.get(:d)
      {:ok, {:d, :e, :f}}

  """
  @spec get(Set.t(), any(), any()) :: {:ok, tuple() | nil} | {:error, any()}
  def get(%Set{table: table}, key, default \\ nil) do
    case Base.lookup(table, key) do
      {:ok, []} -> {:ok, default}
      {:ok, [x | []]} -> {:ok, x}
      {:ok, _} -> {:error, :invalid_set}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `get/3` but unwraps or raises on error.
  """
  @spec get!(Set.t(), any(), any()) :: tuple() | nil
  def get!(%Set{} = set, key, default \\ nil), do: unwrap_or_raise(get(set, key, default))

  @doc """
  Returns element in specified position of record with specified key.

  ## Examples

      iex> Set.new!()
      iex> |> Set.put!({:a, :b, :c})
      iex> |> Set.put!({:d, :e, :f})
      iex> |> Set.get_element(:d, 2)
      {:ok, :e}

  """
  @spec get_element(Set.t(), any(), non_neg_integer()) :: {:ok, any()} | {:error, any()}
  def get_element(%Set{table: table}, key, pos), do: Base.lookup_element(table, key, pos)

  @doc """
  Same as `get_element/3` but unwraps or raises on error.
  """
  @spec get_element!(Set.t(), any(), non_neg_integer()) :: any()
  def get_element!(%Set{} = set, key, pos), do: unwrap_or_raise(get_element(set, key, pos))

  @doc """
  Returns records in the specified Set that match the specified pattern.

  For more information on the match pattern, see the [erlang documentation](http://erlang.org/doc/man/ets.html#match-2)

  ## Examples

      iex> Set.new!(ordered: true)
      iex> |> Set.put!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :i, :j}])
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
      iex> Set.put!(set, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
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
      iex> Set.put!(set, [{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}])
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
  Returns records in the specified Set that match the specified match specification.

  For more information on the match specification, see the [erlang documentation](http://erlang.org/doc/man/ets.html#select-2)

  ## Examples

      iex> Set.new!(ordered: true)
      iex> |> Set.put!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :i, :j}])
      iex> |> Set.select([{{:"$1", :b, :"$2", :_},[],[:"$$"]}])
      {:ok, [[:a, :c], [:h, :i]]}

  """
  @spec select(Set.t(), Ets.match_spec()) :: {:ok, [tuple()]} | {:error, any()}
  def select(%Set{table: table}, spec) when is_list(spec),
    do: Base.select(table, spec)

  @doc """
  Same as `select/2` but unwraps or raises on error.
  """
  @spec select!(Set.t(), Ets.match_spec()) :: [tuple()]
  def select!(%Set{} = set, spec) when is_list(spec),
    do: unwrap_or_raise(select(set, spec))

  @doc """
  Deletes records in the specified Set that match the specified match specification.

  For more information on the match specification, see the [erlang documentation](http://erlang.org/doc/man/ets.html#select_delete-2)

  ## Examples

      iex> set = Set.new!(ordered: true)
      iex> set
      iex> |> Set.put!([{:a, :b, :c, :d}, {:e, :c, :f, :g}, {:h, :b, :c, :h}])
      iex> |> Set.select_delete([{{:"$1", :b, :"$2", :_},[{:"==", :"$2", :c}],[true]}])
      {:ok, 2}
      iex> Set.to_list!(set)
      [{:e, :c, :f, :g}]

  """
  @spec select_delete(Set.t(), Ets.match_spec()) :: {:ok, [tuple()]} | {:error, any()}
  def select_delete(%Set{table: table}, spec) when is_list(spec),
    do: Base.select_delete(table, spec)

  @doc """
  Same as `select_delete/2` but unwraps or raises on error.
  """
  @spec select_delete!(Set.t(), Ets.match_spec()) :: [tuple()]
  def select_delete!(%Set{} = set, spec) when is_list(spec),
    do: unwrap_or_raise(select_delete(set, spec))

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
      iex> Set.get!(set, :a)
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
  Deletes all records in specified Set.

  ## Examples

      iex> set = Set.new!()
      iex> set
      iex> |> Set.put!({:a, :b, :c})
      iex> |> Set.put!({:b, :b, :c})
      iex> |> Set.put!({:c, :b, :c})
      iex> |> Set.to_list!()
      [{:c, :b, :c}, {:b, :b, :c}, {:a, :b, :c}]
      iex> Set.delete_all(set)
      iex> Set.to_list!(set)
      []

  """
  @spec delete_all(Set.t()) :: {:ok, Set.t()} | {:error, any()}
  def delete_all(%Set{table: table} = set), do: Base.delete_all_records(table, set)

  @doc """
  Same as `delete_all/1` but unwraps or raises on error.
  """
  @spec delete_all!(Set.t()) :: Set.t()
  def delete_all!(%Set{} = set), do: unwrap_or_raise(delete_all(set))

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
      {:ok, {table, info}} ->
        {:ok, %Set{table: table, info: info, ordered: info[:type] == :ordered_set}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `wrap_existing/1` but unwraps or raises on error.
  """
  @spec wrap_existing!(Ets.table_identifier()) :: Set.t()
  def wrap_existing!(table_identifier), do: unwrap_or_raise(wrap_existing(table_identifier))
end
