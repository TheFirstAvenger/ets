defmodule Ets.Table do
  use Ets.Utils

  @moduledoc """
  Module for performing table level operations on `:ets` tables.
  """

  @doc """
  Returns :ok/:error tuple. :ok tuple contains list of table identifiers (atoms or references).

  ## Examples

      iex> {:ok, all} = Ets.Table.all()
      iex> Enum.member?(all, :my_ets_table)
      false

      iex> Ets.Table.New.set(:my_ets_table)
      iex> {:ok, all} = Ets.Table.all()
      iex> Enum.member?(all, :my_ets_table)
      true

  """
  @spec all() :: {:ok, [Ets.table_identifier()]} | {:error, any()}
  def all() do
    catch_error do
      {:ok, :ets.all()}
    end
  end

  @doc """
  Same as delete/1 but raises on :error.

  """
  @spec all!() :: [Ets.table_identifier()]
  def all!(), do: unwrap_or_raise(all())

  @doc """
  Deletes a table.

  Returns :ok/:error tuple. :ok tuple contains table identifier given.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> Enum.member?(Ets.Table.all!(), :my_ets_table)
      true
      iex> Ets.Table.delete!(:my_ets_table)
      :my_ets_table
      iex> Enum.member?(Ets.Table.all!(), :my_ets_table)
      false

  """
  @spec delete(Ets.table_identifier()) ::
          {:ok, Ets.table_identifier()} | {:error, :table_not_found}
  def delete(table) do
    catch_error do
      catch_table_not_found table do
        :ets.delete(table)
        {:ok, table}
      end
    end
  end

  @doc """
  Same as delete/1 but raises on :error.

  Returns table identifier.
  """
  @spec delete!(Ets.table_identifier()) :: Ets.table_identifier()
  def delete!(table), do: unwrap_or_raise(delete(table))

  @doc """
  Looks up info on table.

  Returns :ok/:error tuple. :ok tuple contains keyword list of info on table.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> {:ok, info} = Ets.Table.info(:my_ets_table)
      iex> info[:type]
      :set
      iex> info[:named_table]
      true
      iex> info[:protection]
      :protected

  """
  @spec info(Ets.table_identifier()) :: {:ok, keyword()} | {:error, :table_not_found}
  def info(table) do
    catch_error do
      case :ets.info(table) do
        :undefined -> {:error, :table_not_found}
        x -> {:ok, x}
      end
    end
  end

  @doc """
  Same as `info/1` but raises on :error

  Returns keyword list of info on table.
  """
  @spec info!(Ets.table_identifier()) :: keyword()
  def info!(table), do: unwrap_or_raise(info(table))

  @doc """
  Renames the specified table to the specified name.

  Returns :ok/:error tuple. :ok tuple contains the specified new name of the table.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> ref = Ets.Table.info!(:my_ets_table)[:id]
      iex> Ets.Table.rename(:new_name, :my_ets_table)
      iex> ref == Ets.Table.info!(:new_name)[:id]
      true

  """
  @spec rename(Ets.table_name(), Ets.table_identifier()) ::
          {:ok, Ets.table_name()} | {:error, :table_not_found}
  def rename(new_name, table) do
    catch_error do
      catch_table_not_found table do
        name = :ets.rename(table, new_name)
        {:ok, name}
      end
    end
  end

  @doc """
  Same as rename/2 but raises on :error.

  Returns the specified new name of the table
  """
  @spec rename!(Ets.table_name(), Ets.table_identifier()) :: Ets.table_name()
  def rename!(new_name, table), do: unwrap_or_raise(rename(new_name, table))

  @doc """
  Returns contents of table as a list of tuples.

  Returns :ok/:error tuple. :ok tuple contains table contents as a list.

  ## Examples

      iex> Ets.Table.New.bag(:my_ets_table)
      iex> Ets.insert_multi([:a, :b, :c], :my_ets_table, :key1)
      iex> Ets.insert_multi([:a, :b, :c], :my_ets_table, :key2)
      iex> Ets.Table.to_list(:my_ets_table)
      {:ok, [{:key2, :a}, {:key2, :b}, {:key2, :c}, {:key1, :a}, {:key1, :b}, {:key1, :c}]}

  """
  @spec to_list(Ets.table_identifier()) :: {:ok, [tuple()]} | {:error, :table_not_found}
  def to_list(table) do
    catch_error do
      catch_table_not_found table do
        {:ok, :ets.tab2list(table)}
      end
    end
  end

  @doc """
  Same as `to_list/2` but raises on :error.

  Returns table contents as a list.
  """
  @spec to_list!(Ets.table_identifier()) :: [tuple()]
  def to_list!(table), do: unwrap_or_raise(to_list(table))

  @doc """
  Locates table with the specified name.

  Returns :ok/:error tuple. :ok tuple contains table reference.

  ## Examples

      iex> Ets.Table.New.set(:my_ets_table)
      iex> {:ok, ref} = Ets.Table.whereis(:my_ets_table)
      iex> is_reference(ref)
      true

  """
  @spec whereis(atom()) :: {:ok, Ets.ets_table_reference()} | {:error, :table_not_found}
  def whereis(table_name) when is_atom(table_name) do
    catch_error do
      case :ets.whereis(table_name) do
        :undefined -> {:error, :table_not_found}
        x -> {:ok, x}
      end
    end
  end

  @doc """
  Same as `whereis/1` but raises on :error.

  Returns table reference
  """
  @spec whereis!(atom()) :: Ets.ets_table_reference()
  def whereis!(table), do: unwrap_or_raise(whereis(table))
end
