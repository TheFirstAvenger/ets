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
      def fetch(bag, key) do
        __MODULE__
        |> apply(@access_delegation[:find], [bag, key])
        |> case do
          {:ok, []} -> {:ok, nil}
          {:ok, result} -> {:ok, result}
          _ -> :error
        end
      end

      @doc false
      @doc since: "0.7.0"
      @impl true
      def get_and_update(bag, key, function) do
        __MODULE__
        |> apply(@access_delegation[:find], [bag, key])
        |> case do
          {:ok, value} when is_tuple(value) or (is_list(value) and length(value) > 0) ->
            case function.(value) do
              :pop ->
                {value, apply(__MODULE__, @access_delegation[:delete], [bag, key])}

              {^value, updated} ->
                bag = apply(__MODULE__, @access_delegation[:delete], [bag, key])
                bag = apply(__MODULE__, @access_delegation[:add], [bag, updated])
                {value, bag}
            end

          _ ->
            case function.(nil) do
              :pop ->
                {nil, bag}

              {nil, updated} ->
                {nil, apply(__MODULE__, @access_delegation[:add], [bag, updated])}
            end
        end
      end

      @doc false
      @doc since: "0.7.0"
      @impl true
      def pop(bag, key) do
        __MODULE__
        |> apply(@access_delegation[:find], [bag, key])
        |> case do
          {:ok, []} -> {nil, bag}
          {:ok, result} -> {result, apply(__MODULE__, @access_delegation[:delete], [bag, key])}
          _ -> {:error, bag}
        end
      end
    end
  end
end
