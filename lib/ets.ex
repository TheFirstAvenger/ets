defmodule Ets do
  @moduledoc """
  Ets, an Elixir wrapper for Erlang's [`:ets`](http://erlang.org/doc/man/ets.html) module.

  New `:ets` tables can be created using the [Ets.New](Ets.New.html) module.

  """

  @type table_name :: atom()
  @type ets_table_reference :: :ets.tid()
  @type table_identifier :: table_name | ets_table_reference

  @type insert_multi_values :: [{any(), any()}]

  ## Insert

  @doc """
  Inserts a value into the specified table with the specified key.

  Returns inserted value.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.insert(:a, :my_ets_table, :my_key)
      :a

  Designed to be used in pipelines:

      iex> Ets.New.bag(:my_ets_table)
      iex> _inserted = "myVal"
      iex> |> String.to_atom()
      iex> |> Ets.insert(:my_ets_table, :my_key)
      :myVal

  """
  @spec insert(any(), table_identifier, any()) :: list()
  def insert(value, table, key) do
    :ets.insert(table, {key, value})
    value
  end

  @doc """
  Inserts a value into the specified table with the specified key.

  Returns error if key already exists.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.insert_new(:a, :my_ets_table, :my_key)
      {:ok, :a}
      iex> Ets.insert_new(:a, :my_ets_table, :my_key)
      {:error, :already_exists}

  """
  @spec insert_new(any(), table_identifier, any()) :: {:error, :already_exists} | {:ok, any()}
  def insert_new(value, table, key) do
    if :ets.insert_new(table, {key, value}) do
      {:ok, value}
    else
      {:error, :already_exists}
    end
  end

  @doc """
  Inserts a value into the specified table with the specified key.

  Raises if key already exists.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.insert_new!(:a, :my_ets_table, :my_key)
      :a

  Designed to be used in pipelines:

      iex> Ets.New.bag(:my_ets_table)
      iex> _inserted = "myVal"
      iex> |> String.to_atom()
      iex> |> Ets.insert_new!(:my_ets_table, :my_key)
      :myVal

  """
  @spec insert_new!(any(), table_identifier, any()) :: list()
  def insert_new!(value, table, key) do
    case insert_new(value, table, key) do
      {:ok, value} -> value
      {:error, reason} -> raise "Ets.insert_new!/3 failed #{inspect(reason)}"
    end
  end

  ## Insert Multi

  @doc """
  Inserts a list of key/values pairs into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of two-item tuples, the first item is the key, and the second the
  value to insert for that key. Returns the inserted key/value pairs.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> [{:key1, :val1}, {:key2, :val2}]
      iex> |> Ets.insert_multi(:my_ets_table)
      [{:key1, :val1}, {:key2, :val2}]

  """
  @spec insert_multi(insert_multi_values, table_identifier) :: list()
  def insert_multi(key_value_pairs, table) when is_list(key_value_pairs) do
    :ets.insert(table, key_value_pairs)
    key_value_pairs
  end

  @doc """
  Inserts a list of key/values pairs into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of two-item tuples, the first item is the key, and the second the
  value to insert for that key. Returns :ok with the inserted values, or an error if
  one of the keys already exists.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> vals = [{:key1, :val1}, {:key2, :val2}]
      iex> Ets.insert_multi_new(vals, :my_ets_table)
      {:ok, [{:key1, :val1}, {:key2, :val2}]}
      iex> Ets.insert_multi_new(vals, :my_ets_table)
      {:error, :already_exists}

  """
  @spec insert_multi_new(insert_multi_values, table_identifier) ::
          {:error, :already_exists} | {:ok, any()}
  def insert_multi_new(key_value_pairs, table) when is_list(key_value_pairs) do
    if :ets.insert_new(table, key_value_pairs) do
      {:ok, key_value_pairs}
    else
      {:error, :already_exists}
    end
  end

  @doc """
  Inserts a list of key/values pairs into specified table in an
  [atomic and isolated](http://erlang.org/doc/man/ets.html#concurrency) manner.

  First parameter is a list of two-item tuples, the first item is the key, and the second the
  value to insert for that key. Returns inserted values, or raises an error if one of the
  keys already exists.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> vals = [{:key1, :val1}, {:key2, :val2}]
      iex> Ets.insert_multi_new!(vals, :my_ets_table)
      [{:key1, :val1}, {:key2, :val2}]

  """
  @spec insert_multi_new!(insert_multi_values, table_identifier) :: list()
  def insert_multi_new!(key_value_pairs, table) when is_list(key_value_pairs) do
    case insert_multi_new(key_value_pairs, table) do
      {:ok, key_value_pairs} -> key_value_pairs
      {:error, reason} -> raise "Ets.insert_multi_new!/2 failed #{inspect(reason)}"
    end
  end

  ## Lookup

  @doc """
  Looks up values for given key in specified table.

  Returns a value for the specified key. Returns nil when none found, and error when multiple found.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.lookup(:key, :my_ets_table)
      {:ok, nil}
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.lookup(:key, :my_ets_table)
      {:ok, :a}
      iex> Ets.insert(:b, :my_ets_table, :key)
      iex> Ets.lookup(:key, :my_ets_table)
      {:error, :multi_found}

  """
  @spec lookup(any(), table_identifier) :: {:ok, any() | nil} | {:error, :multi_found}
  def lookup(key, table) do
    case lookup_multi(key, table) do
      [] -> {:ok, nil}
      [value | []] -> {:ok, value}
      _ -> {:error, :multi_found}
    end
  end

  @doc """
  Looks up value for given key in specified table.

  Returns a value for the specified key. Returns nil when none found, and raises error when multiple found.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.lookup!(:key, :my_ets_table)
      nil
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.lookup!(:key, :my_ets_table)
      :a

  """
  @spec lookup!(any(), table_identifier) :: any() | nil
  def lookup!(key, table) do
    case lookup(key, table) do
      {:ok, value} -> value
      {:error, reason} -> raise "Ets.lookup!/2 failed #{inspect(reason)}"
    end
  end

  @doc """
  Looks up values for given key in specified table.

  Returns :ok and a list of found values

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      iex> Ets.lookup!(:key, :my_ets_table)
      nil
      iex> Ets.insert(:a, :my_ets_table, :key)
      iex> Ets.insert(:b, :my_ets_table, :key)
      iex> Ets.insert(:c, :my_ets_table, :key)
      iex> Ets.lookup_multi(:key, :my_ets_table)
      [:a, :b, :c]

  """
  @spec lookup_multi(any(), table_identifier) :: [any()]
  def lookup_multi(key, table) do
    :ets.lookup(table, key)
    |> Enum.map(&elem(&1, 1))
  end
end
