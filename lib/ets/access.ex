defmodule Ets.Access do
  @moduledoc false

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @access_delegation find: Keyword.get(opts, :find, :find),
                         delete: Keyword.get(opts, :delete, :delete),
                         add: Keyword.get(opts, :add, :add)

      @behaviour Access

      @doc false
      @doc since: "0.7.0"
      @impl true
      def fetch(table, key) do
        __MODULE__
        |> apply(@access_delegation[:find], [table, key])
        |> case do
          {:ok, []} -> {:ok, nil}
          {:ok, result} -> {:ok, normalize(table, result)}
          _ -> :error
        end
      end

      @doc false
      @doc since: "0.7.0"
      @impl true
      def get_and_update(table, key, function) do
        __MODULE__
        |> apply(@access_delegation[:find], [table, key])
        |> case do
          {:ok, value} when is_tuple(value) or (is_list(value) and length(value) > 0) ->
            case function.(value) do
              :pop ->
                {normalize(table, value),
                 apply(__MODULE__, @access_delegation[:delete], [table, key])}

              {^value, updated} ->
                table = apply(__MODULE__, @access_delegation[:delete], [table, key])
                table = apply(__MODULE__, @access_delegation[:add], [table, updated])
                {normalize(table, value), table}
            end

          _ ->
            case function.(nil) do
              :pop ->
                {nil, table}

              {nil, updated} ->
                {nil, apply(__MODULE__, @access_delegation[:add], [table, updated])}
            end
        end
      end

      @doc false
      @doc since: "0.7.0"
      @impl true
      def pop(table, key) do
        __MODULE__
        |> apply(@access_delegation[:find], [table, key])
        |> case do
          {:ok, []} ->
            {nil, table}

          {:ok, result} ->
            {normalize(table, result),
             apply(__MODULE__, @access_delegation[:delete], [table, key])}

          _ ->
            {:error, table}
        end
      end

      @spec keypos(table :: __MODULE__.t()) :: integer
      defp keypos(table), do: __MODULE__.info!(table)[:keypos] - 1

      @spec normalize(__MODULE__.t(), nil | Tuple.t() | List.t()) :: nil | Tuple.t() | term()
      defp normalize(_, nil), do: nil

      defp normalize(table, result) when is_tuple(result) do
        result
        |> Tuple.delete_at(keypos(table))
        |> detupleize()
      end

      defp normalize(table, result) when is_list(result),
        do: Enum.map(result, &normalize(table, &1))

      @spec detupleize(tuple :: Tuple.t()) :: Tuple.t() | term()
      defp detupleize({term}), do: term
      defp detupleize(any) when is_tuple(any), do: any
    end
  end
end
