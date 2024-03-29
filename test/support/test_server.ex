defmodule ETS.TestServer do
  @moduledoc """
  A test process for receiving ETS table ownership messages.
  """
  use GenServer

  alias ETS.Bag
  alias ETS.KeyValueSet
  alias ETS.Set

  require ETS.Bag
  require ETS.KeyValueSet
  require ETS.Set

  def start_link(_) do
    GenServer.start_link(__MODULE__, :init_state)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  Set.accept :set_test, set, from, :init_state do
    send(from, {:thank_you, set})
    send(self(), {:check_state, Set})
    {:noreply, set}
  end

  KeyValueSet.accept :kv_test, kv_set, from, :init_state do
    send(from, {:thank_you, kv_set})
    send(self(), {:check_state, KeyValueSet})
    {:noreply, kv_set}
  end

  Bag.accept :bag_test, bag, from, :init_state do
    send(from, {:thank_you, bag})
    send(self(), {:check_state, Bag})
    {:noreply, bag}
  end

  def handle_info({:check_state, type}, state) do
    %^type{} = state
    {:noreply, state}
  end
end
