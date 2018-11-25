defmodule Ets.Table.New do
  use Ets.Utils

  @moduledoc """
  Provides functionality to create `:ets` tables. Type of table is specified by picking the appropriate
  function. Specifying an atom as the first parameter will result in a named table, not specifying will
  result in an unnamed table. All functions return {:ok, return} | {:error, reason} tuples, and have a bang version (ending in !)
  which returns the raw value or raises on :error. Named versions return the name of the table, unnamed versions return a
  reference to the table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.bag()
      iex> is_reference(ref)
      true

      iex> Ets.Table.New.bag(:my_ets_table)
      {:ok, :my_ets_table}

  # Options

  All variations take keyword options:

  ```
  protection: :private, :protected, :public
  heir: :none | {heir_pid, heir_data}
  keypos: integer
  read_concurrency: boolean
  write_concurrency: boolean
  compressed: boolean
  ```

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.bag(protection: :private, heir: {self(), :data}, keypos: 5)
      iex> is_reference(ref)
      true

      iex> Ets.Table.New.bag(:my_ets_table, protection: :public, heir: :none, keypos: 2)
      {:ok, :my_ets_table}

  """

  @type option ::
          {:protection, :private | :protected | :public}
          | {:heir, :none | {pid(), any()}}
          | {:keypos, non_neg_integer()}
          | {:write_concurrency, boolean()}
          | {:read_concurrency, boolean()}
          | {:compressed, boolean()}

  @type options :: [option]

  @type table_types :: :bag | :duplicate_bag | :ordered_set | :set
  @type protection_types :: :public | :protected | :private

  @type new_return ::
          {:ok, Ets.ets_table_reference()} | {:error, {:invalid_options, any()} | :unknown_error}
  @type new_named_return ::
          {:ok, atom()}
          | {:error, :table_alrady_exists | {:invalid_options, any()} | :unknown_error}

  @table_types [:bag, :duplicate_bag, :ordered_set, :set]
  @protection_types [:public, :protected, :private]

  ## Bag

  @doc """
  Creates a new unnamed `:ets` table with the type `:bag` and default options.

  Returns :ok/:error tuple. :ok tuple contains table reference

  """
  @spec bag() :: new_return
  def bag(), do: bag([])

  @doc """
  Same as `bag/0` but raises on :error.

  Returns reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.bag()
      iex> is_reference(ref)
      true

  """
  @spec bag!() :: Ets.ets_table_reference()
  def bag!(), do: unwrap_or_raise(bag())

  @doc """
  Creates a new unnamed `:ets` table with the type `:bag` and specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.bag(protection: :private)
      iex> is_reference(ref)
      true

  """
  @spec bag(options()) :: new_return
  def bag(opts) when is_list(opts), do: table(:bag, opts)

  @doc """
  Same as `bag/1` but raises on :error.

  Returns reference of newly created table.
  """
  @spec bag!(options()) :: Ets.ets_table_reference()
  def bag!(opts) when is_list(opts), do: unwrap_or_raise(bag(opts))

  @doc """
  Creates a new named `:ets` table with the type `:bag` and any specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.bag(:my_ets_table, protection: :private)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.bag(:my_ets_table)
      {:ok, :my_ets_table}
      iex> Ets.Table.New.bag(:my_ets_table)
      {:error, :table_already_exists}

  """
  @spec bag(Ets.table_name(), options) :: new_named_return
  def bag(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :bag, opts)

  @doc """
  Same as `bag/2` but raises on :error.

  Returns reference of newly created table.
  """
  @spec bag!(Ets.table_name(), options) :: Ets.table_name()
  def bag!(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: unwrap_or_raise(bag(name, opts))

  ## Duplicate Bag

  @doc """
  Creates a new unnamed `:ets` table with the type `:duplicate_bag` and default options.

  Returns :ok/:error tuple. :ok tuple contains table reference

  """
  @spec duplicate_bag() :: new_return
  def duplicate_bag(), do: duplicate_bag([])

  @doc """
  Same as `duplicate_bag/0` but raises on :error.

  Returns reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.duplicate_bag()
      iex> is_reference(ref)
      true

  """
  @spec duplicate_bag!() :: Ets.ets_table_reference()
  def duplicate_bag!(), do: unwrap_or_raise(duplicate_bag())

  @doc """
  Creates a new unnamed `:ets` table with the type `:duplicate_bag` and specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.duplicate_bag(protection: :private)
      iex> is_reference(ref)
      true

  """
  @spec duplicate_bag(options) :: new_return
  def duplicate_bag(opts) when is_list(opts), do: table(:duplicate_bag, opts)

  @doc """
  Same as `duplicate_bag/1` but raises on :error.

  Returns reference of newly created table.
  """
  @spec duplicate_bag!(options) :: Ets.ets_table_reference()
  def duplicate_bag!(opts) when is_list(opts), do: unwrap_or_raise(duplicate_bag(opts))

  @doc """
  Creates a new named `:ets` table with the type `:duplicate_bag` and any specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table

  ## Examples

      iex> Ets.Table.New.duplicate_bag(:my_ets_table)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.duplicate_bag(:my_ets_table, protection: :private)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.duplicate_bag(:my_ets_table)
      {:ok, :my_ets_table}
      iex> Ets.Table.New.duplicate_bag(:my_ets_table)
      {:error, :table_already_exists}

  """
  @spec duplicate_bag(Ets.table_name(), options) :: new_named_return
  def duplicate_bag(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :duplicate_bag, opts)

  @doc """
  Same as `duplicate_bag/2` but raises on :error.

  Returns reference of newly created table.
  """
  @spec duplicate_bag!(Ets.table_name(), options) :: Ets.table_name()
  def duplicate_bag!(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: unwrap_or_raise(duplicate_bag(name, opts))

  ## Ordered Set

  @doc """
  Creates a new unnamed `:ets` table with the type `:ordered_set` and default options.

  Returns :ok/:error tuple. :ok tuple contains table reference

  """
  @spec ordered_set() :: new_return
  def ordered_set(), do: ordered_set([])

  @doc """
  Same as `ordered_set/0` but raises on :error.

  Returns reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.ordered_set()
      iex> is_reference(ref)
      true

  """
  @spec ordered_set!() :: Ets.ets_table_reference()
  def ordered_set!(), do: unwrap_or_raise(ordered_set())

  @doc """
  Creates a new unnamed `:ets` table with the type `:ordered_set` and specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.ordered_set(protection: :private)
      iex> is_reference(ref)
      true

  """
  @spec ordered_set(options) :: new_return
  def ordered_set(opts) when is_list(opts), do: table(:ordered_set, opts)

  @doc """
  Same as `ordered_set/1` but raises on :error.

  Returns reference of newly created table.
  """
  @spec ordered_set!(options) :: Ets.ets_table_reference()
  def ordered_set!(opts) when is_list(opts), do: unwrap_or_raise(ordered_set(opts))

  @doc """
  Creates a new named `:ets` table with the type `:ordered_set` and any specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table

  ## Examples

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.ordered_set(:my_ets_table, protection: :private)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.ordered_set(:my_ets_table)
      {:ok, :my_ets_table}
      iex> Ets.Table.New.ordered_set(:my_ets_table)
      {:error, :table_already_exists}

  """
  @spec ordered_set(Ets.table_name(), options) :: new_named_return
  def ordered_set(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :ordered_set, opts)

  @doc """
  Same as `ordered_set/2` but raises on :error.

  Returns reference of newly created table.
  """
  @spec ordered_set!(Ets.table_name(), options) :: Ets.table_name()
  def ordered_set!(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: unwrap_or_raise(ordered_set(name, opts))

  ## Set

  @doc """
  Creates a new unnamed `:ets` table with the type `:set` and default options.

  Returns :ok/:error tuple. :ok tuple contains table reference

  """
  @spec set() :: new_return
  def set(), do: set([])

  @doc """
  Same as `set/0` but raises on :error.

  Returns reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.set()
      iex> is_reference(ref)
      true

  """
  @spec set!() :: Ets.ets_table_reference()
  def set!(), do: unwrap_or_raise(set())

  @doc """
  Creates a new unnamed `:ets` table with the type `:set` and specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table.

  ## Examples

      iex> {:ok, ref} = Ets.Table.New.set(protection: :private)
      iex> is_reference(ref)
      true

  """
  @spec set(options) :: new_return
  def set(opts) when is_list(opts), do: table(:set, opts)

  @doc """
  Same as `set/1` but raises on :error.

  Returns reference of newly created table.
  """
  @spec set!(options) :: Ets.ets_table_reference()
  def set!(opts) when is_list(opts), do: unwrap_or_raise(set(opts))

  @doc """
  Creates a new named `:ets` table with the type `:set` and any specified options.

  Returns :ok/:error tuple. :ok tuple contains reference of newly created table

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.set(:my_ets_table, protection: :private)
      {:ok, :my_ets_table}

      iex> Ets.Table.New.set(:my_ets_table)
      {:ok, :my_ets_table}
      iex> Ets.Table.New.set(:my_ets_table)
      {:error, :table_already_exists}

  """
  @spec set(Ets.table_name(), options) :: new_named_return
  def set(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :set, opts)

  @doc """
  Same as `set/2` but raises on :error.

  Returns reference of newly created table.
  """
  @spec set!(Ets.table_name(), options) :: Ets.table_name()
  def set!(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: unwrap_or_raise(set(name, opts))

  ## Private
  @spec table(table_types, options) :: new_return
  defp table(type, opts) when type in @table_types and is_list(opts) do
    catch_error do
      case parse_opts([type], opts) do
        {:ok, parsed_opts} -> {:ok, :ets.new(nil, parsed_opts)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec table_named(Ets.table_name(), table_types, options()) :: new_named_return
  def table_named(name, type, opts)
      when is_atom(name) and is_list(opts) and type in @table_types do
    catch_error do
      catch_table_already_exists name do
        case parse_opts([type, :named_table], opts) do
          {:ok, parsed_opts} -> {:ok, :ets.new(name, parsed_opts)}
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  @spec parse_opts(list(), options) :: {:ok, list()} | {:error, {:invalid_option, any()}}
  defp parse_opts(acc, [{:protection, protection} | tl]) when protection in @protection_types,
    do: parse_opts([protection | acc], tl)

  defp parse_opts(acc, [{:heir, {pid, heir_data}} | tl]) when is_pid(pid),
    do: parse_opts([{:heir, pid, heir_data} | acc], tl)

  defp parse_opts(acc, [{:heir, :none} | tl]), do: parse_opts([{:heir, :none} | acc], tl)

  defp parse_opts(acc, [{:keypos, keypos} | tl]) when is_integer(keypos) and keypos >= 0,
    do: parse_opts([{:keypos, keypos} | acc], tl)

  defp parse_opts(acc, [{:write_concurrency, wc} | tl]) when is_boolean(wc),
    do: parse_opts([{:write_concurrency, wc} | acc], tl)

  defp parse_opts(acc, [{:read_concurrency, rc} | tl]) when is_boolean(rc),
    do: parse_opts([{:read_concurrency, rc} | acc], tl)

  defp parse_opts(acc, [{:compressed, true} | tl]), do: parse_opts([:compressed | acc], tl)
  defp parse_opts(acc, [{:compressed, false} | tl]), do: parse_opts(acc, tl)

  defp parse_opts(acc, []), do: {:ok, acc}

  defp parse_opts(_, [bad_val | _]),
    do: {:error, {:invalid_option, bad_val}}
end
