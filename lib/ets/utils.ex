defmodule Ets.Utils do
  @moduledoc """
  Contains helper macros used by `Ets` modules.
  """
  defmacro __using__(_) do
    quote do
      require Logger

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
              case :ets.whereis(unquote(table)) do
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

      defmacrop catch_bad_records(records, err \\ :invalid_record, do: do_block) do
        quote do
          try do
            unquote(do_block)
          rescue
            e in ArgumentError ->
              if Enum.any?(unquote(records), fn
                   record when is_tuple(record) -> false
                   record -> true
                 end) do
                reraise(e, __STACKTRACE__)
              else
                {:error, unquote(err)}
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
