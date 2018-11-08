defmodule EtsTest do
  use ExUnit.Case
  doctest Ets

  setup do
    ctx = %{
      bag: Ets.New.bag()
      # duplicate_bag: Ets.New.duplicate_bag(),
      # ordered_set: Ets.New.ordered_set(),
      # set: Ets.New.set(),
    }

    {:ok, ctx}
  end

  describe "Insert" do
    test "insert/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert :a = Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_new!/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert :a = Ets.insert_new!(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_new!/3 raises on duplicate and does not insert", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert :a = Ets.insert_new!(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]

      assert_raise RuntimeError, "Ets.insert_new!/3 failed :already_exists", fn ->
        Ets.insert_new!(:a, bag, :key)
      end

      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_multi/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.insert_multi(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi_new!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.insert_multi_new!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi_new!/2 raises on duplicate and does not insert", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.insert_multi_new!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]

      assert_raise RuntimeError, "Ets.insert_multi_new!/2 failed :already_exists", fn ->
        Ets.insert_multi_new!(to_insert, bag)
      end

      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end
  end

  describe "Lookup" do
    test "lookup/2 returns nil on new table", %{bag: bag} do
      assert Ets.lookup(:key, bag) == {:ok, nil}
    end

    test "lookup/2 returns inserted value", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert Ets.lookup(:key, bag) == {:ok, :a}
    end

    test "lookup/2 returns error on multiple found", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      Ets.insert(:b, bag, :key)
      assert Ets.lookup(:key, bag) == {:error, :multi_found}
    end

    test "lookup!/2 returns nil on new table", %{bag: bag} do
      assert Ets.lookup!(:key, bag) == nil
    end

    test "lookup!/2 returns inserted value", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert Ets.lookup!(:key, bag) == :a
    end

    test "lookup!/2 raises when multiple found", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      Ets.insert(:b, bag, :key)

      assert_raise RuntimeError, "Ets.lookup!/2 failed :multi_found", fn ->
        Ets.lookup!(:key, bag)
      end
    end
  end
end
