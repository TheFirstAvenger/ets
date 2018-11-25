defmodule EtsTest do
  use ExUnit.Case
  doctest Ets

  setup do
    ctx = %{
      bag: Ets.Table.New.bag!(),
      # duplicate_bag: Ets.Table.New.duplicate_bag!(),
      ordered_set: Ets.Table.New.ordered_set!()
      # set: Ets.Table.New.set!(),
    }

    {:ok, ctx}
  end

  describe "Insert" do
    test "insert/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert {:ok, :a} = Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert/3 returns :table_not_found when table missing" do
      assert {:error, :table_not_found} == Ets.insert(:a, :not_a_table, :key)
    end

    test "insert!/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert :a = Ets.insert!(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert!/3 raises :table_not_found when table missing" do
      assert_raise RuntimeError, "Ets.insert!/3 returned {:error, :table_not_found}", fn ->
        Ets.insert!(:a, :not_a_table, :key)
      end
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

      assert_raise RuntimeError,
                   "Ets.insert_new!/3 returned {:error, :key_already_exists}",
                   fn ->
                     Ets.insert_new!(:a, bag, :key)
                   end

      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_new!/3 raises on missing table" do
      assert_raise RuntimeError,
                   "Ets.insert_new!/3 returned {:error, :table_not_found}",
                   fn ->
                     Ets.insert_new!(:a, :not_a_table, :key)
                   end
    end

    test "insert_multi/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert {:ok, ^to_insert} = Ets.insert_multi(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi/2 returns :table_not_found on missing table" do
      assert Ets.insert_multi([{:a, :b}], :not_a_table) == {:error, :table_not_found}
    end

    test "insert_multi!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.insert_multi!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi!/2 raises :table_not_found on missing table" do
      assert_raise RuntimeError,
                   "Ets.insert_multi!/2 returned {:error, :table_not_found}",
                   fn -> Ets.insert_multi!([{:a, :b}], :not_a_table) end
    end

    test "insert_multi/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [:a, :b]
      assert {:ok, ^to_insert} = Ets.insert_multi(to_insert, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}, {:key, :b}]
    end

    test "insert_multi/3 returns :table_not_found on missing table" do
      assert Ets.insert_multi([:a, :b], :not_a_table, :key) == {:error, :table_not_found}
    end

    test "insert_multi!/3 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [:a, :b]
      assert ^to_insert = Ets.insert_multi!(to_insert, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}, {:key, :b}]
    end

    test "insert_multi!/3 raises :table_not_found on missing table" do
      assert_raise RuntimeError,
                   "Ets.insert_multi!/3 returned {:error, :table_not_found}",
                   fn -> Ets.insert_multi!([:a, :b], :not_a_table, :key) end
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

      assert_raise RuntimeError,
                   "Ets.insert_multi_new!/2 returned {:error, :key_already_exists}",
                   fn ->
                     Ets.insert_multi_new!(to_insert, bag)
                   end

      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi_new!/2 raises on missing table" do
      assert_raise RuntimeError,
                   "Ets.insert_multi_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.insert_multi_new!([{:a, :b}], :not_a_table)
                   end
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

    test "lookup/2 returns error on missing table" do
      assert Ets.lookup(:key, :not_a_table) == {:error, :table_not_found}
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

      assert_raise RuntimeError, "Ets.lookup!/2 returned {:error, :multi_found}", fn ->
        Ets.lookup!(:key, bag)
      end
    end

    test "lookup!/2 raises when missing table" do
      assert_raise RuntimeError, "Ets.lookup!/2 returned {:error, :table_not_found}", fn ->
        Ets.lookup!(:key, :not_a_table)
      end
    end
  end

  describe "Lookup Multi" do
    test "lookup_multi/2 returns nil on new table", %{bag: bag} do
      assert Ets.lookup_multi(:key, bag) == {:ok, []}
    end

    test "lookup_multi/2 returns inserted value", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert Ets.lookup_multi(:key, bag) == {:ok, [:a]}
    end

    test "lookup_multi/2 returns multiple on multiple found", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      Ets.insert(:b, bag, :key)
      assert Ets.lookup_multi(:key, bag) == {:ok, [:a, :b]}
    end

    test "lookup_multi/2 returns error on missing table" do
      assert Ets.lookup_multi(:key, :not_a_table) == {:error, :table_not_found}
    end

    test "lookup_multi!/2 returns nil on new table", %{bag: bag} do
      assert Ets.lookup_multi!(:key, bag) == []
    end

    test "lookup_multi!/2 returns inserted value", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert Ets.lookup_multi!(:key, bag) == [:a]
    end

    test "lookup_multi!/2 returns when multiple found", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      Ets.insert(:b, bag, :key)

      assert Ets.lookup_multi!(:key, bag) == [:a, :b]
    end

    test "lookup_multi!/2 raises when missing table" do
      assert_raise RuntimeError,
                   "Ets.lookup_multi!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.lookup_multi!(:key, :not_a_table)
                   end
    end
  end

  describe "First" do
    test "first/1 returns first key", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.first(ordered_set) == {:ok, :key1}
    end

    test "first/1 returns error on empty table", %{bag: bag} do
      assert Ets.first(bag) == {:error, :empty_table}
    end

    test "first!/1 returns first key", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.first!(ordered_set) == :key1
    end

    test "first!/1 raises error on empty table", %{bag: bag} do
      assert_raise RuntimeError, "Ets.first!/1 returned {:error, :empty_table}", fn ->
        Ets.first!(bag)
      end
    end

    test "first!/1 raises error on missing table" do
      assert_raise RuntimeError, "Ets.first!/1 returned {:error, :table_not_found}", fn ->
        Ets.first!(:not_a_table)
      end
    end
  end

  describe "Last" do
    test "last/1 returns last key", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.last(ordered_set) == {:ok, :key4}
    end

    test "last/1 returns error on empty table", %{bag: bag} do
      assert Ets.last(bag) == {:error, :empty_table}
    end

    test "last!/1 returns last key", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.last!(ordered_set) == :key4
    end

    test "last!/1 raises error on empty table", %{bag: bag} do
      assert_raise RuntimeError, "Ets.last!/1 returned {:error, :empty_table}", fn ->
        Ets.last!(bag)
      end
    end

    test "last!/1 raises error on missing table" do
      assert_raise RuntimeError, "Ets.last!/1 returned {:error, :table_not_found}", fn ->
        Ets.last!(:not_a_table)
      end
    end
  end

  describe "Next" do
    test "next/2 returns next key or :end of table", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.next(:key1, ordered_set) == {:ok, :key2}
      assert Ets.next(:key2, ordered_set) == {:ok, :key3}
      assert Ets.next(:key3, ordered_set) == {:ok, :key4}
      assert Ets.next(:key4, ordered_set) == {:error, :end_of_table}
    end

    test "next!/2 returns next key or raises on :end of table", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.next!(:key1, ordered_set) == :key2
      assert Ets.next!(:key2, ordered_set) == :key3
      assert Ets.next!(:key3, ordered_set) == :key4

      assert_raise RuntimeError, "Ets.next!/2 returned {:error, :end_of_table}", fn ->
        Ets.next!(:key4, ordered_set)
      end
    end

    test "next!/2 raises error on missing table" do
      assert_raise RuntimeError, "Ets.next!/2 returned {:error, :table_not_found}", fn ->
        Ets.next!(:not_a_key, :not_a_table)
      end
    end
  end

  describe "Previous" do
    test "previous/2 returns previous key or :end of table", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.previous!(:key2, ordered_set) == :key1
      assert Ets.previous!(:key3, ordered_set) == :key2
      assert Ets.previous!(:key4, ordered_set) == :key3
      assert Ets.previous(:key1, ordered_set) == {:error, :start_of_table}
    end

    test "previous!/2 returns next key or raises on :end of table", %{ordered_set: ordered_set} do
      Ets.insert(:a, ordered_set, :key1)
      Ets.insert(:a, ordered_set, :key2)
      Ets.insert(:a, ordered_set, :key3)
      Ets.insert(:a, ordered_set, :key4)
      assert Ets.previous!(:key2, ordered_set) == :key1
      assert Ets.previous!(:key3, ordered_set) == :key2
      assert Ets.previous!(:key4, ordered_set) == :key3

      assert_raise RuntimeError,
                   "Ets.previous!/2 returned {:error, :start_of_table}",
                   fn ->
                     Ets.previous!(:key1, ordered_set)
                   end
    end

    test "previous!/2 raises error on missing table" do
      assert_raise RuntimeError,
                   "Ets.previous!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.previous!(:not_a_key, :not_a_table)
                   end
    end
  end

  describe "Has Key" do
    test "has_key/2 returns true when key exists", %{bag: bag} do
      Ets.insert!(:a, bag, :key)
      assert Ets.has_key(:key, bag) == {:ok, true}
    end

    test "has_key/2 returns false when key doesn't exist", %{bag: bag} do
      assert Ets.has_key(:key, bag) == {:ok, false}
    end

    test "has_key/2 returns error when table doesn't exist" do
      assert Ets.has_key(:key, :not_a_table) == {:error, :table_not_found}
    end

    test "has_key!/2 returns true when key exists", %{bag: bag} do
      Ets.insert!(:a, bag, :key)
      assert Ets.has_key!(:key, bag) == true
    end

    test "has_key!/2 returns false when key doesn't exist", %{bag: bag} do
      assert Ets.has_key!(:key, bag) == false
    end

    test "has_key!/2 returns error when table doesn't exist" do
      assert_raise RuntimeError,
                   "Ets.has_key!/2 returned {:error, :table_not_found}",
                   fn -> Ets.has_key!(:key, :not_a_table) end
    end
  end

  describe "Delete" do
    test "delete/2 deletes specified key", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
      Ets.delete(:key, bag)
      assert :ets.lookup(bag, :key) == []
    end

    test "delete/2 returns :table_not_found on missing table" do
      assert Ets.delete(:key, :not_a_table) == {:error, :table_not_found}
    end

    test "delete!/2 deletes specified key", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
      Ets.delete!(:key, bag)
      assert :ets.lookup(bag, :key) == []
    end

    test "delete!/2 returns :table_not_found on missing table" do
      assert_raise RuntimeError, "Ets.delete!/2 returned {:error, :table_not_found}", fn ->
        Ets.delete!(:key, :not_a_table)
      end
    end

    test "delete_all/1 deletes specified key", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
      Ets.delete_all(bag)
      assert :ets.lookup(bag, :key) == []
    end

    test "delete_all/1 returns :table_not_found on missing table" do
      assert Ets.delete_all(:not_a_table) == {:error, :table_not_found}
    end

    test "delete_all!/1 deletes specified key", %{bag: bag} do
      Ets.insert(:a, bag, :key)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
      Ets.delete_all!(bag)
      assert :ets.lookup(bag, :key) == []
    end

    test "delete_all!/1 returns :table_not_found on missing table" do
      assert_raise RuntimeError,
                   "Ets.delete_all!/1 returned {:error, :table_not_found}",
                   fn ->
                     Ets.delete_all!(:not_a_table)
                   end
    end
  end
end
