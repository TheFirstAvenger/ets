defmodule Ets do
  use Ets.Utils

  @moduledoc """
  Ets, an Elixir wrapper for Erlang's [`:ets`](http://erlang.org/doc/man/ets.html) module.

  New `:ets` tables can be created using the [Ets.Table.New](Ets.Table.New.html) module.

  All functions return {:error, :table_not_found} (or raise in bang versions) when the table does not exist.

  """

  @type table_name :: atom()
  @type ets_table_reference :: :ets.tid()
  @type table_identifier :: table_name | ets_table_reference

  ## Insert

  @doc """
  Inserts a value into the specified table with the specified key.

  Returns :ok or :error tuple. :ok tuple contains with inserted value.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.insert(:a, :my_ets_table, :my_key)
      {:ok, :a}

  Designed to be used in pipelines:

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> _inserted = "myVal"
      iex> |> String.to_atom()
      iex> |> Ets.insert(:my_ets_table, :my_key)
      {:ok, :myVal}

  """
  @spec insert(any(), table_identifier, any()) ::
          {:ok, any()} | {:error, :table_not_found | :invalid_key}
  def insert(_, _, :"$end_of_table"), do: {:error, :invalid_key}

  def insert(value, table, key) do
    catch_error do
      catch_table_not_found table do
        :ets.insert(table, {key, value})
        {:ok, value}
      end
    end
  end

  @doc """
  The same as `insert/3`, but raises on :error.

  Returns inserted value.
  """
  @spec insert!(any(), table_identifier, any()) :: any()
  def insert!(value, table, key), do: unwrap_or_raise(insert(value, table, key))

  @doc """
  Inserts a value into the specified table with the specified key.

  Returns :ok or :error tuple. :ok tuple contains inserted value. Returns error if
  key already exists in table.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.insert_new(:a, :my_ets_table, :my_key)
      {:ok, :a}
      iex> Ets.insert_new(:a, :my_ets_table, :my_key)
      {:error, :key_already_exists}

  """
  @spec insert_new(any(), table_identifier, any()) ::
          {:error, :key_already_exists | :table_not_found | :invalid_key} | {:ok, any()}
  def insert_new(_, _, :"$end_of_table"), do: {:error, :invalid_key}

  def insert_new(value, table, key) do
    catch_error do
      catch_table_not_found table do
        if :ets.insert_new(table, {key, value}) do
          {:ok, value}
        else
          {:error, :key_already_exists}
        end
      end
    end
  end

  @doc """
  The same as `insert_new/3`, but raises on :error.

  Returns inserted value.
  """
  @spec insert_new!(any(), table_identifier, any()) :: list()
  def insert_new!(value, table, key), do: unwrap_or_raise(insert_new(value, table, key))

  ## Insert Multi

  @doc """
  Inserts a list of key/values pairs into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of two-item tuples, the first item is the key, and the second the
  value to insert for that key. Returns :ok/:error tuples. :ok tuple contains inserted values.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> [{:key1, :val1}, {:key2, :val2}]
      iex> |> Ets.insert_multi(:my_ets_table)
      {:ok, [{:key1, :val1}, {:key2, :val2}]}

  """
  @spec insert_multi([{any(), any()}], table_identifier) ::
          {:ok, [{any(), any()}]} | {:error, :table_not_found | :invalid_key_value_pair}
  def insert_multi(key_value_pairs, table) when is_list(key_value_pairs) do
    catch_error do
      catch_bad_records key_value_pairs, :invalid_key_value_pair do
        catch_table_not_found table do
          :ets.insert(table, key_value_pairs)
          {:ok, key_value_pairs}
        end
      end
    end
  end

  @doc """
  The same as `insert_multi/2`, but raises on :error.

  Returns inserted key/value pairs.
  """
  @spec insert_multi!([{any(), any()}], table_identifier) :: [{any(), any()}]
  def insert_multi!(key_value_pairs, table) when is_list(key_value_pairs),
    do: unwrap_or_raise(insert_multi(key_value_pairs, table))

  @doc """
  Inserts a list of values for the specified key into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of values. Returns :ok/:error tuples. :ok tuple
  contains inserted values.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.insert_multi([:val1, :val2], :my_ets_table, :key)
      {:ok, [:val1, :val2]}
      iex> Ets.Table.to_list(:my_ets_table)
      {:ok, [{:key, :val1}, {:key, :val2}]}

  """
  @spec insert_multi(list(), table_identifier, any()) ::
          {:ok, list()} | {:error, :table_not_found | :invalid_key}
  def insert_multi(_, _, :"$end_of_table"), do: {:error, :invalid_key}

  def insert_multi(values, table, key) when is_list(values) do
    catch_error do
      catch_table_not_found table do
        :ets.insert(table, Enum.map(values, &{key, &1}))
        {:ok, values}
      end
    end
  end

  @doc """
  Same as `insert_multi/3`, but raises on :error.

  Returns inserted values.
  """
  @spec insert_multi!(list(), table_identifier, any()) :: list()
  def insert_multi!(values, table, key) when is_list(values),
    do: unwrap_or_raise(insert_multi(values, table, key))

  @doc """
  Inserts a list of key/values pairs into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of two-item tuples ({key, value}). Returns :ok/:error tuples. :ok tuple contains inserted values. :error returned if key already exists.
  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> vals = [{:key1, :val1}, {:key2, :val2}]
      iex> Ets.insert_multi_new(vals, :my_ets_table)
      {:ok, [{:key1, :val1}, {:key2, :val2}]}
      iex> Ets.insert_multi_new(vals, :my_ets_table)
      {:error, :key_already_exists}

  """
  @spec insert_multi_new([{any(), {any()}}], table_identifier) ::
          {:error, :key_already_exists | :invalid_key_value_pair | :table_not_found}
          | {:ok, [{any(), any()}]}
  def insert_multi_new(key_value_pairs, table) when is_list(key_value_pairs) do
    catch_error do
      catch_bad_records key_value_pairs, :invalid_key_value_pair do
        catch_table_not_found table do
          if :ets.insert_new(table, key_value_pairs) do
            {:ok, key_value_pairs}
          else
            {:error, :key_already_exists}
          end
        end
      end
    end
  end

  @doc """
  Same as `insert_multi_new/2` but raises on :error.

  Returns inserted key/value pairs.
  """
  @spec insert_multi_new!([{any(), any()}], table_identifier) :: [{any(), any()}]
  def insert_multi_new!(key_value_pairs, table) when is_list(key_value_pairs),
    do: unwrap_or_raise(insert_multi_new(key_value_pairs, table))

  ## Lookup

  @doc """
  Looks up value for given key in specified table.

  Expects zero or one value found. For bag/duplicate_bag, use lookup_multi

  Returns :ok/:error tuples. :ok tuple contains found value, or nil. :error returned on multiple found

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.lookup(:key, :my_ets_table)
      {:ok, nil}
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.lookup(:key, :my_ets_table)
      {:ok, :a}
      iex> Ets.insert(:b, :my_ets_table, :key)
      iex> Ets.lookup(:key, :my_ets_table)
      {:error, :multi_found}

  """
  @spec lookup(any(), table_identifier) ::
          {:ok, any() | nil} | {:error, :multi_found | :table_not_found}
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
  @spec lookup!(any(), table_identifier) :: any() | nil
  def lookup!(key, table), do: unwrap_or_raise(lookup(key, table))

  @doc """
  Looks up values for given key in specified table.

  Returns :ok/:error tuples. :ok tuple contains list of found values. For sets, consider using
  `lookup/2` to avoid having to unwrap list.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.lookup_multi(:key, :my_ets_table)
      {:ok, []}
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.insert(:b, :my_ets_table, :key)
      iex> Ets.insert(:c, :my_ets_table, :key)
      iex> Ets.lookup_multi(:key, :my_ets_table)
      {:ok, [:a, :b, :c]}

  """
  @spec lookup_multi(any(), table_identifier) :: {:ok, [any()]} | {:error, :table_not_found}
  def lookup_multi(key, table) do
    catch_error do
      catch_table_not_found table do
        vals =
          table
          |> :ets.lookup(key)
          |> Enum.map(&elem(&1, 1))

        {:ok, vals}
      end
    end
  end

  @doc """
  Same as `lookup_multi/2` but raises on :error.

  Returns list of found values.
  """
  @spec lookup_multi!(any(), table_identifier) :: [any()]
  def lookup_multi!(key, table), do: unwrap_or_raise(lookup_multi(key, table))

  @doc """
  Determines if specified key exists in specified table.

  Returns :ok/:error tuples. :ok tuple contains boolean indicating if the key was found.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> Ets.has_key(:key, :my_ets_table)
      {:ok, false}
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.has_key(:key, :my_ets_table)
      {:ok, true}

  """
  @spec has_key(any(), table_identifier) :: {:ok, boolean()} | {:error, :table_not_found}
  def has_key(key, table) do
    catch_error do
      catch_table_not_found table do
        {:ok, :ets.member(table, key)}
      end
    end
  end

  @doc """
  Same as `has_key/2` but raises on :error.

  Returns boolean indicating if key was found.
  """
  @spec has_key!(any(), table_identifier) :: boolean()
  def has_key!(key, table), do: unwrap_or_raise(has_key(key, table))

  @doc """
  Looks up the first key in the specified table.

  Returns :ok/:error tuples. :ok tuple contains first key.

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      iex> Ets.first(:my_ets_table)
      {:error, :empty_table}
      iex> Ets.insert(:val, :my_ets_table, :key1)
      iex> Ets.insert(:val, :my_ets_table, :key2)
      iex> Ets.first(:my_ets_table)
      {:ok, :key1}

  """
  @spec first(table_identifier) :: {:ok, any()} | {:error, :empty_table | :table_not_found}
  def first(table) do
    catch_error do
      catch_table_not_found table do
        case :ets.first(table) do
          :"$end_of_table" -> {:error, :empty_table}
          x -> {:ok, x}
        end
      end
    end
  end

  @doc """
  Same as `first/1` but raises on :error

  Returns first key in table.
  """
  @spec first!(table_identifier) :: any()
  def first!(table), do: unwrap_or_raise(first(table))

  @doc """
  Looks up the last key in the specified table.

  Returns :ok/:error tuples. :ok tuple contains last key.

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      iex> Ets.last(:my_ets_table)
      {:error, :empty_table}
      iex> Ets.insert(:val, :my_ets_table, :key1)
      iex> Ets.insert(:val, :my_ets_table, :key2)
      iex> Ets.last(:my_ets_table)
      {:ok, :key2}

  """
  @spec last(table_identifier) :: {:ok, any()} | {:error, :empty_table | :table_not_found}
  def last(table) do
    catch_error do
      catch_table_not_found table do
        case :ets.last(table) do
          :"$end_of_table" -> {:error, :empty_table}
          x -> {:ok, x}
        end
      end
    end
  end

  @doc """
  Same as `last/1` but raises on :error

  Returns last key in table.
  """
  @spec last!(table_identifier) :: any()
  def last!(table), do: unwrap_or_raise(last(table))

  @doc """
  Looks up the next key in the specified table.

  Returns :ok/:error tuples. :ok tuple contains next key. {:error, :end_of_table} when end
  of table reached

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      iex> Ets.insert(:val, :my_ets_table, :key1)
      iex> Ets.insert(:val, :my_ets_table, :key2)
      iex> Ets.next(:key1, :my_ets_table)
      {:ok, :key2}
      iex> Ets.next(:key2, :my_ets_table)
      {:error, :end_of_table}

  """
  @spec next(any(), table_identifier) :: {:ok, any()} | {:error, :end_of_table | :table_not_found}
  def next(key, table) do
    catch_error do
      catch_table_not_found table do
        case :ets.next(table, key) do
          :"$end_of_table" -> {:error, :end_of_table}
          x -> {:ok, x}
        end
      end
    end
  end

  @doc """
  Same as `next/1` but raises on :error.

  Returns next key in table.
  """
  @spec next!(any(), table_identifier) :: any()
  def next!(key, table), do: unwrap_or_raise(next(key, table))

  @doc """
  Looks up the previous key in the specified table.

  Returns :ok/:error tuples. :ok tuple contains previous key. {:error, :start_of_table} when
  start of table reached.

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      iex> Ets.insert(:val, :my_ets_table, :key1)
      iex> Ets.insert(:val, :my_ets_table, :key2)
      iex> Ets.previous(:key2, :my_ets_table)
      {:ok, :key1}
      iex> Ets.previous(:key1, :my_ets_table)
      {:error, :start_of_table}

  """
  @spec previous(any(), table_identifier) ::
          {:ok, any()} | {:error, :start_of_table | :table_not_found}
  def previous(key, table) do
    catch_error do
      catch_table_not_found table do
        case :ets.prev(table, key) do
          :"$end_of_table" -> {:error, :start_of_table}
          x -> {:ok, x}
        end
      end
    end
  end

  @doc """
  Same as `previous/1` but raises on :error

  Returns previous key in table.
  """
  @spec previous!(any(), table_identifier) :: any()
  def previous!(key, table), do: unwrap_or_raise(previous(key, table))

  @doc """
  Deletes specified key from table.

  Returns :ok/:error tuple. :ok tuple contains specified key.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.lookup!(:key, :my_ets_table)
      :a
      iex> Ets.delete(:key, :my_ets_table)
      {:ok, :key}
      iex> Ets.lookup!(:key, :my_ets_table)
      nil

  """
  @spec delete(any(), table_identifier) :: {:ok, any()} | {:error, :table_not_found}
  def delete(key, table) do
    catch_error do
      catch_table_not_found table do
        :ets.delete(table, key)
        {:ok, key}
      end
    end
  end

  @spec delete!(any(), table_identifier) :: any()
  def delete!(key, table), do: unwrap_or_raise(delete(key, table))

  @doc """
  Deletes all entries in the table.

  Returns :ok/:error tuple. :ok tuple contains table identifier passed to function.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> Ets.insert(:val, :my_ets_table, :key)
      iex> Ets.delete_all(:my_ets_table)
      iex> Ets.Table.to_list(:my_ets_table)
      {:ok, []}

  """
  @spec delete_all(table_identifier) :: {:ok, table_identifier} | {:error, :table_not_found}
  def delete_all(table) do
    catch_error do
      catch_table_not_found table do
        :ets.delete_all_objects(table)
        {:ok, table}
      end
    end
  end

  @doc """
  Same as `delete_all/2` but raises on :error.

  Returns table identifier passed to function.
  """
  @spec delete_all!(table_identifier) :: table_identifier
  def delete_all!(table), do: unwrap_or_raise(delete_all(table))
end
