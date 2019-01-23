defmodule Ets.Set.KeyValueSet do
  @moduledoc """
  The Key Value Set is an extension of `Ets.Set` which abstracts the concept of tuple records
  away, replacing it with the standard concept of key/value. Behind the scenes, the set stores
  its records as {key, value}.

  ## Examples

      iex> {:ok, kvset} = KeyValueSet.new()
      iex> KeyValueSet.put(kvset, :my_key, :my_val)
      iex> KeyValueSet.get(kvset, :my_key)
      {:ok, :my_val}

  """
  use Ets.Utils
  use Ets.Set.KeyValueSet.Macros

  alias Ets
  alias Ets.Set
  alias Ets.Set.KeyValueSet

  @type t :: %__MODULE__{
          set: Set.t()
        }

  @type set_options :: [Ets.Base.option() | {:ordered, boolean()}]

  defstruct set: nil

  @doc """
  Creates new Key Value Set module with the specified options.

  Possible Options can be found in `Ets.Set` with the difference that specifying a `keypos`
  will result in an error.

  ## Examples

      iex> {:ok, kvset} = KeyValueSet.new(ordered: true,read_concurrency: true, compressed: false)
      iex> KeyValueSet.info!(kvset)[:read_concurrency]
      true

      # Named :ets tables via the name keyword
      iex> {:ok, kvset} = KeyValueSet.new(name: :my_ets_table)
      iex> KeyValueSet.info!(kvset)[:name]
      :my_ets_table

  """
  @spec new(set_options) :: {:error, any()} | {:ok, KeyValueSet.t()}
  def new(opts \\ []) when is_list(opts) do
    with(
      {:keypos, false} <- {:keypos, Keyword.has_key?(opts, :keypos)},
      {:ok, set} <- Set.new(opts)
    ) do
      {:ok, %KeyValueSet{set: set}}
    else
      {:keypos, true} -> {:error, {:invalid_option, {:keypos, Keyword.get(opts, :keypos)}}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `new/1` but unwraps or raises on error.
  """
  @spec new!(set_options) :: KeyValueSet.t()
  def new!(opts \\ []), do: unwrap_or_raise(new(opts))

  @doc """
  Wraps an existing :ets :set or :ordered_set in a KeyValueSet struct.

  ## Examples

      iex> :ets.new(:my_ets_table, [:set, :named_table])
      iex> {:ok, set} = KeyValueSet.wrap_existing(:my_ets_table)
      iex> KeyValueSet.info!(set)[:name]
      :my_ets_table

  """
  @spec wrap_existing(Ets.table_identifier()) :: {:ok, KeyValueSet.t()} | {:error, any()}
  def wrap_existing(table_identifier) do
    with(
      {:ok, set} <- Set.wrap_existing(table_identifier),
      {:ok, info} <- Set.info(set),
      {:keypos, true} <- {:keypos, info[:keypos] == 1}
    ) do
      {:ok, %KeyValueSet{set: set}}
    else
      {:keypos, false} -> {:error, :invalid_keypos}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `wrap_existing/1` but unwraps or raises on error.
  """
  @spec wrap_existing!(Ets.table_identifier()) :: KeyValueSet.t()
  def wrap_existing!(table_identifier), do: unwrap_or_raise(wrap_existing(table_identifier))

  @doc """
  Puts given value into table for given key.

  ## Examples

      iex> kvset = KeyValueSet.new!(ordered: true)
      iex> {:ok, kvset} = KeyValueSet.put(kvset, :a, :b)
      iex> KeyValueSet.get!(kvset, :a)
      :b

  """
  def put(%KeyValueSet{set: set} = key_value_set, key, value) do
    case Set.put(set, {key, value}) do
      {:ok, _} -> {:ok, key_value_set}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `put/3` but unwraps or raises on error.
  """
  @spec put!(KeyValueSet.t(), any(), any()) :: KeyValueSet.t()
  def put!(%KeyValueSet{} = key_value_set, key, value),
    do: unwrap_or_raise(put(key_value_set, key, value))

  @doc """
  Same as `put/3` but doesn't put record if the key already exists.

  ## Examples

      iex> set = KeyValueSet.new!(ordered: true)
      iex> {:ok, _} = KeyValueSet.put_new(set, :a, :b)
      iex> {:ok, _} = KeyValueSet.put_new(set, :a, :c) # skips due toduplicate :a key
      iex> KeyValueSet.to_list!(set)
      [{:a, :b}]

  """
  @spec put_new(KeyValueSet.t(), any(), any()) :: {:ok, KeyValueSet.t()} | {:error, any()}
  def put_new(%KeyValueSet{set: set} = key_value_set, key, value) do
    case Set.put_new(set, {key, value}) do
      {:ok, _} -> {:ok, key_value_set}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `put_new/3` but unwraps or raises on error.
  """
  @spec put_new!(KeyValueSet.t(), any(), any()) :: KeyValueSet.t()
  def put_new!(%KeyValueSet{} = key_value_set, key, value),
    do: unwrap_or_raise(put_new(key_value_set, key, value))

  @doc """
  Returns value for specified key or the provided default (nil if not specified) if no record found.

  ## Examples

      iex> KeyValueSet.new!()
      iex> |> KeyValueSet.put!(:a, :b)
      iex> |> KeyValueSet.put!(:c, :d)
      iex> |> KeyValueSet.put!(:e, :f)
      iex> |> KeyValueSet.get(:c)
      {:ok, :d}

  """
  @spec get(KeyValueSet.t(), any(), any()) :: {:ok, any()} | {:error, any()}
  def get(%KeyValueSet{set: set}, key, default \\ nil) do
    case Set.get(set, key, default) do
      {:ok, {_, value}} -> {:ok, value}
      {:ok, ^default} -> {:ok, default}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `get/3` but unwraps or raises on error
  """
  @spec get!(KeyValueSet.t(), any(), any()) :: any()
  def get!(%KeyValueSet{} = key_value_set, key, default \\ nil),
    do: unwrap_or_raise(get(key_value_set, key, default))

  def info(key_value_set, force_update \\ false)
  def info!(key_value_set, force_update \\ false)

  delegate_to_set :info, 2, ret: keyword(), second_param_type: boolean() do
    "Returns info on set"
  end

  delegate_to_set :get_table, 1, ret: Ets.table_reference(), can_raise: false do
    "Returns underlying `:ets` table reference"
  end

  delegate_to_set(:first, 1, do: "Returns first key in KeyValueSet")
  delegate_to_set(:last, 1, do: "Returns last key in KeyValueSet")
  delegate_to_set(:next, 2, do: "Returns next key in KeyValueSet")
  delegate_to_set(:previous, 2, do: "Returns previous key in KeyValueSet")
  delegate_to_set(:has_key, 2, do: "Determines if specified key exists in KeyValueSet")
  delegate_to_set(:delete, 1, do: "Deletes KeyValueSet")
  delegate_to_set(:delete, 2, do: "Deletes record with key in KeyValueSet")
  delegate_to_set(:delete_all, 1, do: "Deletes all records in KeyValueSet")
  delegate_to_set(:to_list, 1, do: "Returns contents of table as a list")
end
