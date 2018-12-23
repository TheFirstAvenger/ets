defmodule EtsTest do
  use ExUnit.Case
  doctest Ets

  describe "all" do
    test "all!/0 returns tables successfully" do
      all = :ets.all()
      all2 = Ets.all!()
      assert length(all) == length(all2)
      assert Enum.count(all, &type_old(&1, :set)) == Enum.count(all2, &type_new(&1, :set))

      assert Enum.count(all, &type_old(&1, :ordered_set)) ==
               Enum.count(all2, &type_new(&1, :ordered_set))

      assert Enum.count(all, &type_old(&1, :bag)) == Enum.count(all2, &type_new(&1, :bag))

      assert Enum.count(all, &type_old(&1, :duplicate_bag)) ==
               Enum.count(all2, &type_new(&1, :duplicate_bag))
    end
  end

  def type_old(tid, type), do: tid |> :ets.info() |> Keyword.get(:type) |> Kernel.==(type)
  def type_new(%{info: info}, type), do: info |> Keyword.get(:type) |> Kernel.==(type)
end
