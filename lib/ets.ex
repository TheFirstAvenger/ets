defmodule Ets do
  use Ets.Utils

  @moduledoc """
  Ets, an Elixir wrapper for Erlang's [`:ets`](http://erlang.org/doc/man/ets.html) module.

  See `Ets.Set` for information on creating and managing Sets.

  `Ets.Bag` coming soon.

  """

  @type table_name :: atom()
  @type ets_table_reference :: :ets.tid()
  @type table_identifier :: table_name | ets_table_reference
  @type match_pattern :: atom() | tuple()

  @doc """
  Returns list of current :ets tables, each wrapped as either `Ets.Set` or `Ets.Bag`.

  NOTE: `Ets.Bag` is not yet implemented. This list returns only :set and :ordered_set tables, both wrapped as `Ets.Set`.

  ## Examples

      iex> {:ok, all} = Ets.all()
      iex> x = length(all)
      iex> Ets.Set.new!()
      iex> {:ok, all} = Ets.all()
      iex> length(all) == x + 1
      true

  """
  @spec all() :: {:ok, [Ets.table_identifier()]} | {:error, any()}
  def all() do
    catch_error do
      all =
        :ets.all()
        |> Enum.map(fn tid ->
          case Ets.Set.wrap_existing(tid) do
            {:ok, set} -> set
            {:error, _} -> nil
          end
        end)
        |> Enum.filter(&Kernel.!(is_nil(&1)))

      {:ok, all}
    end
  end

  @doc """
  Same as all/1 but unwraps or raises on :error.

  """
  @spec all!() :: [Ets.table_identifier()]
  def all!(), do: unwrap_or_raise(all())
end
