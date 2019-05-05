defmodule Ets.Utils do
  @moduledoc """
  Contains helper macros used by `Ets` modules.
  """

  defmacro __using__(_) do
    quote do
      require Logger
      import Ets.Utils
    end
  end

  def take_opt(opts, key, default) do
    val = Keyword.get(opts, key, default)
    {Keyword.drop(opts, [key]), val}
  end

  defmacro catch_error(do: do_block) do
    {func, arity} = __CALLER__.function
    mod = __CALLER__.module

    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          Logger.error(
            "Unknown ArgumentError in #{inspect(unquote(mod))}.#{unquote(func)}/#{unquote(arity)}: #{
              inspect(e)
            }"
          )

          {:error, :unknown_error}
      end
    end
  end

  defmacro catch_table_not_found(table, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          case :ets.info(unquote(table)) do
            :undefined -> {:error, :table_not_found}
            _ -> reraise(e, __STACKTRACE__)
          end
      end
    end
  end

  defmacro catch_table_already_exists(table_name, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          case :ets.whereis(unquote(table_name)) do
            :undefined -> reraise(e, __STACKTRACE__)
            _ -> {:error, :table_already_exists}
          end
      end
    end
  end

  defmacro catch_key_not_found(table, key, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          case Ets.Base.lookup(unquote(table), unquote(key)) do
            {:ok, []} -> {:error, :key_not_found}
            _ -> reraise(e, __STACKTRACE__)
          end
      end
    end
  end

  defmacro catch_bad_records(records, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          if Enum.any?(unquote(records), &(!is_tuple(&1))) do
            {:error, :invalid_record}
          else
            reraise(e, __STACKTRACE__)
          end
      end
    end
  end

  defmacro catch_record_too_small(table, record, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          if :ets.info(unquote(table))[:keypos] > tuple_size(unquote(record)) do
            {:error, :record_too_small}
          else
            reraise(e, __STACKTRACE__)
          end
      end
    end
  end

  defmacro catch_records_too_small(table, records, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          keypos = :ets.info(unquote(table))[:keypos]

          unquote(records)
          |> Enum.filter(&(keypos > tuple_size(&1)))
          |> case do
            [] -> reraise(e, __STACKTRACE__)
            _ -> {:error, :record_too_small}
          end
      end
    end
  end

  defmacro catch_invalid_select_spec(spec, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          if Ets.Utils.valid_select_spec?(unquote(spec)) do
            reraise(e, __STACKTRACE__)
          else
            {:error, :invalid_select_spec}
          end
      end
    end
  end

  def valid_select_spec?(spec) when is_list(spec) do
    spec
    |> Enum.all?(fn s ->
      s |> is_tuple() and
        s |> tuple_size() == 3 and
        s |> elem(0) |> is_tuple() and
        s |> elem(1) |> is_list() and
        s |> elem(2) |> is_list()
    end)
  end

  def valid_select_spec?(_not_a_list), do: false

  defmacro catch_write_protected(table, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          info = :ets.info(unquote(table))

          if info[:protection] == :public or info[:owner] == self() do
            reraise(e, __STACKTRACE__)
          else
            {:error, :write_protected}
          end
      end
    end
  end

  defmacro catch_read_protected(table, do: do_block) do
    quote do
      try do
        unquote(do_block)
      rescue
        e in ArgumentError ->
          info = :ets.info(unquote(table))

          if info[:protection] in [:public, :protected] or info[:owner] == self() do
            reraise(e, __STACKTRACE__)
          else
            {:error, :read_protected}
          end
      end
    end
  end

  defmacro unwrap_or_raise(expr) do
    {func, arity} = __CALLER__.function
    mod = __CALLER__.module

    quote do
      case unquote(expr) do
        {:ok, value} ->
          value

        {:error, reason} ->
          raise "#{inspect(unquote(mod))}.#{unquote(func)}/#{unquote(arity)} returned {:error, #{
                  inspect(reason)
                }}"
      end
    end
  end

  defmacro unwrap(expr) do
    quote do
      {:ok, value} = unquote(expr)
      value
    end
  end
end
