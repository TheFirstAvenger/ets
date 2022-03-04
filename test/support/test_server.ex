defmodule ETS.TestServer do
  @moduledoc """
  A test process for receiving ETS table ownership messages.
  """
  use GenServer
  alias ETS.{Bag, KeyValueSet, Set}
  require ETS.{Bag, KeyValueSet, Set}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :init_state)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  Set.accept :set_test, set, from, :init_state do
    send(from, {:thank_you, set})
    send(self(), {:check_state, Set, from})
    {:noreply, set}
  end

  Set.accept :invalid, set, _from, :init_state do
    {:noreply, set}
  end

  KeyValueSet.accept :kv_test, kv_set, from, :init_state do
    send(from, {:thank_you, kv_set})
    send(self(), {:check_state, KeyValueSet, from})
    {:noreply, kv_set}
  end

  Bag.accept :bag_test, bag, from, :init_state do
    send(from, {:thank_you, bag})
    send(self(), {:check_state, Bag, from})
    {:noreply, bag}
  end

  def handle_info({:check_state, type, test_process}, state) do
    case state do
      %^type{} -> send(test_process, :state_saved_ok)
      _ -> send(test_process, :error)
    end

    {:noreply, state}
  end
end
