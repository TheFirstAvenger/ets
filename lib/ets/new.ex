defmodule Ets.New do
  @moduledoc """
  Provides functionality to create `:ets` tables. Type of table is specified by picking the appropriate
  function. Specifying an atom as the first parameter will result in a named table, not specifying will
  result in an unnamed table. Named versions return the name of the table, unnamed versions return a
  reference to the table.

  ## Examples

      iex> ref = Ets.New.bag()
      iex> is_reference(ref)
      true

      iex> Ets.New.bag(:my_ets_table)
      :my_ets_table

  # Options

  All variations take keyword options:

  ```
  access: :private, :protected, :public
  heir: :none | {heir_pid, heir_data}
  keypos: integer
  ```

  ## Examples

      iex> ref = Ets.New.bag(access: :private, heir: {self(), :data}, keypos: 5)
      iex> is_reference(ref)
      true

      iex> Ets.New.bag(:my_ets_table, access: :public, heir: :none, keypos: 2)
      :my_ets_table

  """

  @type option ::
          {:access, :private | :protected | :public}
          | {:heir, :none | {pid(), any()}}
          | {:keypos, non_neg_integer()}
  @type options :: [option]

  @type table_types :: :bag | :duplicate_bag | :ordered_set | :set
  @type access_types :: :public | :protected | :private

  @table_types [:bag, :duplicate_bag, :ordered_set, :set]
  @access_types [:public, :protected, :private]

  @doc """
  Creates a new unnamed `:ets` table with the type `:bag` and default options.

  ## Examples

      iex> ref = Ets.New.bag()
      iex> is_reference(ref)
      true

  """
  @spec bag() :: Ets.ets_table_reference()
  def bag(), do: bag([])

  @doc """
  Creates a new unnamed `:ets` table with the type `:bag` and specified options.

  ## Examples

      iex> ref = Ets.New.bag(access: :private)
      iex> is_reference(ref)
      true

  """
  @spec bag(options) :: Ets.ets_table_reference()
  def bag(opts) when is_list(opts), do: table(:bag, opts)

  @doc """
  Creates a new named `:ets` table with the type `:bag` and any specified options.

  ## Examples

      iex> Ets.New.bag(:my_ets_table)
      :my_ets_table

      iex> Ets.New.bag(:my_ets_table, access: :private)
      :my_ets_table

  """
  @spec bag(Ets.table_name(), options) :: Ets.table_name()
  def bag(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :bag, opts)

  @doc """
  Creates a new unnamed `:ets` table with the type `:duplicate_bag` and default options.

  ## Examples

      iex> ref = Ets.New.duplicate_bag()
      iex> is_reference(ref)
      true

  """
  @spec duplicate_bag() :: Ets.ets_table_reference()
  def duplicate_bag(), do: duplicate_bag([])

  @doc """
  Creates a new unnamed `:ets` table with the type `:duplicate_bag` and specified options.

  ## Examples

      iex> ref = Ets.New.duplicate_bag()
      iex> is_reference(ref)
      true

  """
  @spec duplicate_bag(options) :: Ets.ets_table_reference()
  def duplicate_bag(opts) when is_list(opts), do: table(:duplicate_bag, opts)

  @doc """
  Creates a new named `:ets` table with the type `:duplicate_bag` and any specified options.

  ## Examples

      iex> Ets.New.duplicate_bag(:my_ets_table)
      :my_ets_table

      iex> Ets.New.duplicate_bag(:my_ets_table, access: :private)
      :my_ets_table

  """
  @spec duplicate_bag(Ets.table_name(), options) :: Ets.table_name()
  def duplicate_bag(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :duplicate_bag, opts)

  @doc """
  Creates a new unnamed `:ets` table with the type `:ordered_set` and default options.

  ## Examples

      iex> ref = Ets.New.ordered_set()
      iex> is_reference(ref)
      true

  """
  @spec ordered_set() :: Ets.ets_table_reference()
  def ordered_set(), do: ordered_set([])

  @doc """
  Creates a new unnamed `:ets` table with the type `:ordered_set` and specified options.

  ## Examples

      iex> ref = Ets.New.ordered_set(access: :private)
      iex> is_reference(ref)
      true

  """
  @spec ordered_set(options) :: Ets.ets_table_reference()
  def ordered_set(opts) when is_list(opts), do: table(:ordered_set, opts)

  @doc """
  Creates a new named `:ets` table with the type `:ordered_set` and any specified options.

  ## Examples

      iex> Ets.New.ordered_set(:my_ets_table)
      :my_ets_table

      iex> Ets.New.ordered_set(:my_ets_table, access: :private)
      :my_ets_table

  """
  @spec ordered_set(Ets.table_name(), options) :: Ets.table_name()
  def ordered_set(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :ordered_set, opts)

  @doc """
  Creates a new unnamed `:ets` table with the type `:set` and default options.

  ## Examples

      iex> ref = Ets.New.set()
      iex> is_reference(ref)
      true

  """
  @spec set() :: Ets.ets_table_reference()
  def set(), do: set([])

  @doc """
  Creates a new unnamed `:ets` table with the type `:set` and specified options.

  ## Examples

      iex> ref = Ets.New.set(access: :private)
      iex> is_reference(ref)
      true

  """
  @spec set(options) :: Ets.ets_table_reference()
  def set(opts) when is_list(opts), do: table(:set, opts)

  @doc """
  Creates a new named `:ets` table with the type `:set` and any specified options.

  ## Examples

      iex> Ets.New.set(:my_ets_table)
      :my_ets_table

      iex> Ets.New.set(:my_ets_table, access: :private)
      :my_ets_table

  """
  @spec set(Ets.table_name(), options) :: Ets.table_name()
  def set(name, opts \\ []) when is_atom(name) and is_list(opts),
    do: table_named(name, :set, opts)

  ## Private
  @spec table(table_types, options) :: Ets.ets_table_reference()
  defp table(type, opts) when type in @table_types do
    :ets.new(nil, parse_opts([type], opts))
  end

  @spec table_named(Ets.table_name(), table_types, options) :: Ets.table_name()
  defp table_named(name, type, opts) when is_atom(name) and type in @table_types do
    :ets.new(name, parse_opts([type, :named_table], opts))
    name
  end

  # TODO: add "Tweaks" options

  @spec parse_opts(any(), options) :: any()
  defp parse_opts(acc, [{:access, access} | tl]) when access in @access_types,
    do: parse_opts([access | acc], tl)

  defp parse_opts(acc, [{:heir, {pid, heir_data}} | tl]) when is_pid(pid),
    do: parse_opts([{:heir, pid, heir_data} | acc], tl)

  defp parse_opts(acc, [{:heir, :none} | tl]), do: parse_opts([{:heir, :none} | acc], tl)

  defp parse_opts(acc, [{:keypos, keypos} | tl]) when is_integer(keypos) and keypos >= 0,
    do: parse_opts([{:keypos, keypos} | acc], tl)

  defp parse_opts(acc, []), do: acc

  defp parse_opts(_, [bad_val | _]),
    do: raise(ArgumentError, "Invalid opt passed to Ets.New: #{inspect(bad_val)}")
end
