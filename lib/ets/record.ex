defmodule Ets.Record do
  use Ets.Utils

  @moduledoc """
  Contains advanced functions for accessing `:ets` tables using the tuple/record notation.
  This module retains most of the improvements found in the `Ets` module (such as improved error
  handling and pipeline optimized parameters), but retains the tuple/record concept.
  """

  @type match_pattern :: atom() | tuple()

  ## Insert

  @doc """
  Inserts a record into the specified table.

  Returns :ok or :error tuple. :ok tuple contains with inserted value.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.Record.insert({:a, :b}, :my_ets_table)
      {:ok, {:a, :b}}

  Designed to be used in pipelines:

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> _inserted = [1, "John", "Doe", 35, "Boston"]
      iex> |> List.to_tuple()
      iex> |> Ets.Record.insert(:my_ets_table)
      {:ok, {1, "John", "Doe", 35, "Boston"}}
      iex> Ets.Record.lookup(1, :my_ets_table)
      {:ok, {1, "John", "Doe", 35, "Boston"}}

  """
  @spec insert(tuple(), Ets.table_identifier()) ::
          {:ok, tuple()} | {:error, :table_not_found | :duplicate_record}
  def insert(record, table) when is_tuple(record) do
    catch_error do
      catch_table_not_found table do
        :ets.insert(table, record)
        {:ok, record}
      end
    end
  end

  @doc """
  The same as `insert/2`, but raises on :error.

  Returns inserted value.
  """
  @spec insert!(tuple(), Ets.table_identifier()) :: any()
  def insert!(value, table) when is_tuple(value), do: unwrap_or_raise(insert(value, table))

  @doc """
  Inserts a value into the specified table with the specified key.

  Returns :ok or :error tuple. :ok tuple contains inserted value. Returns error if
  key already exists in table.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.Record.insert_new({:a, :b}, :my_ets_table)
      {:ok, {:a, :b}}
      iex> Ets.Record.insert_new({:a, :b}, :my_ets_table)
      {:error, :key_already_exists}

  """
  @spec insert_new(tuple(), Ets.table_identifier()) ::
          {:error, :key_already_exists | :table_not_found} | {:ok, tuple()}
  def insert_new(record, table) when is_tuple(record) do
    catch_error do
      catch_table_not_found table do
        if :ets.insert_new(table, record) do
          {:ok, record}
        else
          record_or_key_already_exists(table)
        end
      end
    end
  end

  @doc """
  The same as `insert_new/2`, but raises on :error.

  Returns inserted value.
  """
  @spec insert_new!(tuple(), Ets.table_identifier()) :: tuple()
  def insert_new!(record, table) when is_tuple(record),
    do: unwrap_or_raise(insert_new(record, table))

  ## Insert Multi

  @doc """
  Inserts a list of records into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of tuple records. Returns :ok/:error tuples. :ok tuple contains inserted values.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]
      iex> |> Ets.Record.insert_multi(:my_ets_table)
      {:ok, [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]}

  """
  @spec insert_multi([tuple()], Ets.table_identifier()) ::
          {:ok, [{any(), any()}]} | {:error, :table_not_found}
  def insert_multi(records, table) when is_list(records) do
    catch_error do
      catch_bad_records records do
        catch_table_not_found table do
          :ets.insert(table, records)
          {:ok, records}
        end
      end
    end
  end

  @doc """
  The same as `insert_multi/2`, but raises on :error.

  Returns inserted records.
  """
  @spec insert_multi!([tuple()], Ets.table_identifier()) :: [{any(), any()}]
  def insert_multi!(records, table) when is_list(records),
    do: unwrap_or_raise(insert_multi(records, table))

  @doc """
  Inserts a list of records into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of record tuples. Returns :ok/:error tuples.
  :ok tuple contains inserted records. :error returned if key or record already exists.
  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> vals = [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]
      iex> Ets.Record.insert_multi_new(vals, :my_ets_table)
      {:ok, [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]}
      iex> Ets.Record.insert_multi_new(vals, :my_ets_table)
      {:error, :key_already_exists}

      iex> Ets.Table.New.duplicate_bag(:my_ets_table)
      iex> vals = [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]
      iex> Ets.Record.insert_multi_new(vals, :my_ets_table)
      {:ok, [{1, "John", "Doe", 35, "Boston"}, {2, "Jim", "Smith", 27, "Austin"}]}
      iex> Ets.Record.insert_multi_new(vals, :my_ets_table)
      {:error, :record_already_exists}

  """
  @spec insert_multi_new([tuple()], Ets.table_identifier()) ::
          {:error, :key_already_exists | :record_already_exists | :table_not_found}
          | {:ok, [tuple()]}
  def insert_multi_new(records, table) when is_list(records) do
    catch_error do
      catch_bad_records records do
        catch_table_not_found table do
          if :ets.insert_new(table, records) do
            {:ok, records}
          else
            record_or_key_already_exists(table)
          end
        end
      end
    end
  end

  @doc """
  Same as `insert_multi_new/2` but raises on :error.

  Returns inserted records.
  """
  @spec insert_multi_new!([tuple()], Ets.table_identifier()) :: [tuple()]
  def insert_multi_new!(records, table) when is_list(records),
    do: unwrap_or_raise(insert_multi_new(records, table))

  ## Lookup

  @doc """
  Looks up record for given key in specified table.

  Expects zero or one record found. For bag/duplicate_bag, use lookup_multi

  Returns :ok/:error tuples. :ok tuple contains found record, or nil. :error returned on multiple found

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.Record.lookup(:key, :my_ets_table)
      {:ok, nil}
      iex> Ets.Record.insert({:key, :a}, :my_ets_table)
      iex> Ets.Record.lookup(:key, :my_ets_table)
      {:ok, {:key, :a}}
      iex> Ets.Record.insert({:key, :b}, :my_ets_table)
      iex> Ets.Record.lookup(:key, :my_ets_table)
      {:error, :multi_found}

  """
  @spec lookup(any(), Ets.table_identifier()) ::
          {:ok, tuple() | nil} | {:error, :multi_found | :table_not_found}
  def lookup(key, table) do
    case lookup_multi(key, table) do
      {:error, reason} -> {:error, reason}
      {:ok, []} -> {:ok, nil}
      {:ok, [value | []]} -> {:ok, value}
      {:ok, _} -> {:error, :multi_found}
    end
  end

  @doc """
  Same as `lookup/2` but raises on error.

  Returns found value or nil if not found.
  """
  @spec lookup!(any(), Ets.table_identifier()) :: tuple() | nil
  def lookup!(key, table), do: unwrap_or_raise(lookup(key, table))

  @doc """
  Looks up records for given key in specified table.

  Returns :ok/:error tuples. :ok tuple contains list of found records. For sets, consider using
  `lookup/2` to avoid having to unwrap list.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.Record.lookup_multi(:key, :my_ets_table)
      {:ok, []}
      iex> Ets.Record.insert({:key, :a}, :my_ets_table)
      iex> Ets.Record.insert({:key, :b}, :my_ets_table)
      iex> Ets.Record.insert({:key, :c}, :my_ets_table)
      iex> Ets.Record.lookup_multi(:key, :my_ets_table)
      {:ok, [{:key, :a}, {:key, :b}, {:key, :c}]}

  """
  @spec lookup_multi(any(), Ets.table_identifier()) ::
          {:ok, [tuple()]} | {:error, :table_not_found}
  def lookup_multi(key, table) do
    catch_error do
      catch_table_not_found table do
        vals = :ets.lookup(table, key)
        {:ok, vals}
      end
    end
  end

  @doc """
  Same as `lookup_multi/2` but raises on :error.

  Returns list of found values.
  """
  @spec lookup_multi!(any(), Ets.table_identifier()) :: [tuple()]
  def lookup_multi!(key, table), do: unwrap_or_raise(lookup_multi(key, table))

  @doc """
  Matches records in the specified table against the specified pattern.

  Returns :ok/:error tuples. :ok tuple contains a list of matches, each themselves a list.

  For more information on the match pattern, see the [erlang documentation](http://erlang.org/doc/man/ets.html#match-2)
  """
  @spec match(match_pattern(), Ets.table_identifier()) ::
          {:ok, [list()]} | {:error, :table_not_found}
  def match(pattern, table) do
    catch_error do
      catch_table_not_found table do
        matches = :ets.match(table, pattern)
        {:ok, matches}
      end
    end
  end

  @doc """
  Same as match/2 but raises on error.

  Returns list of matched tuple records.
  """
  @spec match!(match_pattern(), Ets.table_identifier()) :: [list()]
  def match!(pattern, table), do: unwrap_or_raise(match(pattern, table))

  @doc """
  Same as match/2 but limits number of results to the specified limit.

  Returns :ok/:error tuples. :ok tuple contains :end_of_table or a list of matches, each themselves a list, and a
  Continuation for use in match/1

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      iex> Ets.Record.insert_multi([{:a, :b, :c, :d}, {:e, :b, :f, :g}, {:h, :b, :i, :j}], :my_ets_table)
      iex> {:ok, {records, continuation}} = Ets.Record.match({:"$1", :b, :"$2", :_}, :my_ets_table, 2)
      iex> records
      [[:a, :c], [:e, :f]]
      iex> {:ok, {records2, continuation2}} = Ets.Record.match(continuation)
      iex> records2
      [[:h, :i]]
      iex> continuation2
      :end_of_table

  """
  @spec match(match_pattern, Ets.table_identifier(), non_neg_integer()) ::
          {:ok, :end_of_table | {[tuple()], any()}} | {:error, :table_not_found}
  def match(pattern, table, limit) do
    catch_error do
      catch_table_not_found table do
        case :ets.match(table, pattern, limit) do
          {x, :"$end_of_table"} -> {:ok, {x, :end_of_table}}
          {records, continuation} -> {:ok, {records, continuation}}
          :"$end_of_table" -> {:ok, {[], :end_of_table}}
        end
      end
    end
  end

  @doc """
  Same as match/3 but raises on error.

  Returns list of matches, each themeselves a list, and a continuation for use in match/1
  """
  @spec match!(match_pattern, Ets.table_identifier(), non_neg_integer()) :: {[tuple()], any()}
  def match!(pattern, table, limit), do: unwrap_or_raise(match(pattern, table, limit))

  @doc """
  Matches next set of records from a match/3 or match/1 continuation

  Returns :ok/:error tuples. :ok tuple contains :end_of_table or a list of matches, each themselves a list, and a
  Continuation for use in match/1

  See match/3 for examples.

  """
  @spec match(any()) :: {:ok, :end_of_table | {[tuple()], any()}} | {:error, :table_not_found}
  def match(continuation) do
    catch_error do
      case :ets.match(continuation) do
        {x, :"$end_of_table"} -> {:ok, {x, :end_of_table}}
        {records, continuation} -> {:ok, {records, continuation}}
        :"$end_of_table" -> {:ok, {[], :end_of_table}}
      end
    end
  end

  @spec record_or_key_already_exists(Ets.table_identifier()) ::
          {:error, :key_already_exists | :record_already_exists}
  defp record_or_key_already_exists(table) do
    case Ets.Table.info!(table)[:type] do
      :duplicate_bag -> {:error, :record_already_exists}
      _ -> {:error, :key_already_exists}
    end
  end
end
