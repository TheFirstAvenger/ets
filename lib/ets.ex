defmodule Ets do
  use Ets.Utils

  @moduledoc """
  Ets, an Elixir wrapper for Erlang's [`:ets`](http://erlang.org/doc/man/ets.html) module.

  See `Ets.Set` for information on creating and managing Sets, and `Ets.Bag` for information on creating and managing Bags.

  See `Ets.Set.KeyValueSet` for an abstraction which provides standard key/value interaction with Sets.

  """

  @type table_name :: atom()
  @type table_reference :: :ets.tid()
  @type table_identifier :: table_name | table_reference
  @type match_pattern :: :ets.match_pattern()
  @type match_spec :: :ets.match_spec()

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
  @spec all :: {:ok, [Ets.table_identifier()]} | {:error, any()}
  def all do
    catch_error do
      all =
        :ets.all()
        |> Enum.map(fn tid ->
          tid
          |> :ets.info()
          |> Keyword.get(:type)
          |> case do
            type when type in [:set, :ordered_set] -> Ets.Set.wrap_existing!(tid)
            type when type in [:bag, :duplicate_bag] -> Ets.Bag.wrap_existing!(tid)
          end
        end)

      {:ok, all}
    end
  end

  @doc """
  Same as all/1 but unwraps or raises on :error.

  """
  @spec all!() :: [Ets.table_identifier()]
  def all!(), do: unwrap_or_raise(all())
end
