defmodule Ets.Utils do
  @moduledoc """
  Contains helper macros used by `Ets` modules.
  """
  defmacro __using__(_) do
    quote do
      require Logger

      @doc false
      def take_opt(opts, key, default) do
        val = Keyword.get(opts, key, default)
        {Keyword.drop(opts, [key]), val}
      end

      defmacrop catch_error(do: do_block) do
        {func, arity} = __CALLER__.function
        mod = __CALLER__.module

        quote do
          try do
            unquote(do_block)
          rescue
            e in ArgumentError ->
              Logger.error(
                "Unknown ArgumentError in #{inspect(unquote(mod))}.#{unquote(func)}/#{
                  unquote(arity)
                }: #{inspect(e)}"
              )

              {:error, :unknown_error}
          end
        end
      end

      defmacrop catch_table_not_found(table, do: do_block) do
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

      @doc false
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

      defmacrop catch_key_not_found(table, key, do: do_block) do
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

      defmacrop catch_bad_records(records, do: do_block) do
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

      defmacrop unwrap_or_raise(expr) do
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
    end
  end
end
