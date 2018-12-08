defmodule EtsTest do
  use ExUnit.Case
  doctest Ets

  describe "all" do
    test "all!/0 returns tables successfully" do
      Ets.all!()
      |> Enum.each(fn %type{} = _table ->
        assert type in [Ets.Set]
      end)
    end
  end
end
