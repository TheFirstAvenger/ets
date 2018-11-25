defmodule EtsRecordTest do
  use ExUnit.Case
  doctest Ets.Record

  setup do
    ctx = %{
      bag: Ets.Table.New.bag!()
      # duplicate_bag: Ets.Table.New.duplicate_bag!(),
      # ordered_set: Ets.Table.New.ordered_set!()
      # set: Ets.Table.New.set!(),
    }

    {:ok, ctx}
  end

  describe "Insert" do
    test "insert/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert {:ok, {key, :a}} = Ets.Record.insert({:key, :a}, bag)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert/2 returns :table_not_found when table missing" do
      assert {:error, :table_not_found} == Ets.Record.insert({:key, :a}, :not_a_table)
    end

    test "insert!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert {:key, :a} = Ets.Record.insert!({:key, :a}, bag)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert/2 raises :table_not_found when table missing" do
      assert_raise RuntimeError, "Ets.Record.insert!/2 returned {:error, :table_not_found}", fn ->
        Ets.Record.insert!({:key, :a}, :not_a_table)
      end
    end

    test "insert_new!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert {:key, :a} = Ets.Record.insert_new!({:key, :a}, bag)
      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_new!/2 raises on duplicate and does not insert", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      assert {:key, :a} = Ets.Record.insert_new!({:key, :a}, bag)
      assert :ets.lookup(bag, :key) == [{:key, :a}]

      assert_raise RuntimeError,
                   "Ets.Record.insert_new!/2 returned {:error, :key_already_exists}",
                   fn ->
                     Ets.Record.insert_new!({:key, :a}, bag)
                   end

      assert :ets.lookup(bag, :key) == [{:key, :a}]
    end

    test "insert_new!/2 raises on missing table" do
      assert_raise RuntimeError,
                   "Ets.Record.insert_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.Record.insert_new!({:key, :a}, :not_a_table)
                   end
    end

    test "insert_multi/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert {:ok, ^to_insert} = Ets.Record.insert_multi(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi/2 returns :table_not_found on missing table" do
      assert Ets.Record.insert_multi([{:a, :b}], :not_a_table) == {:error, :table_not_found}
    end

    test "insert_multi!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.Record.insert_multi!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi!/2 raises :table_not_found on missing table" do
      assert_raise RuntimeError,
                   "Ets.Record.insert_multi!/2 returned {:error, :table_not_found}",
                   fn -> Ets.Record.insert_multi!([{:a, :b}], :not_a_table) end
    end

    test "insert_multi_new!/2 inserts value", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.Record.insert_multi_new!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi_new!/2 raises on duplicate and does not insert", %{bag: bag} do
      assert :ets.lookup(bag, :key) == []
      to_insert = [{:key1, :a}, {:key2, :b}]
      assert ^to_insert = Ets.Record.insert_multi_new!(to_insert, bag)
      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]

      assert_raise RuntimeError,
                   "Ets.Record.insert_multi_new!/2 returned {:error, :key_already_exists}",
                   fn ->
                     Ets.Record.insert_multi_new!(to_insert, bag)
                   end

      assert :ets.lookup(bag, :key1) == [{:key1, :a}]
      assert :ets.lookup(bag, :key2) == [{:key2, :b}]
    end

    test "insert_multi_new!/2 raises on missing table" do
      assert_raise RuntimeError,
                   "Ets.Record.insert_multi_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.Record.insert_multi_new!([{:a, :b}], :not_a_table)
                   end
    end
  end

  describe "Lookup" do
    test "lookup/2 returns nil on new table", %{bag: bag} do
      assert Ets.Record.lookup(:key, bag) == {:ok, nil}
    end

    test "lookup/2 returns inserted value", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      assert Ets.Record.lookup(:key, bag) == {:ok, {:key, :a}}
    end

    test "lookup/2 returns error on multiple found", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      Ets.Record.insert({:key, :b}, bag)
      assert Ets.Record.lookup(:key, bag) == {:error, :multi_found}
    end

    test "lookup/2 returns error on missing table" do
      assert Ets.Record.lookup(:key, :not_a_table) == {:error, :table_not_found}
    end

    test "lookup!/2 returns nil on new table", %{bag: bag} do
      assert Ets.Record.lookup!(:key, bag) == nil
    end

    test "lookup!/2 returns inserted value", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      assert Ets.Record.lookup!(:key, bag) == {:key, :a}
    end

    test "lookup!/2 raises when multiple found", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      Ets.Record.insert({:key, :b}, bag)

      assert_raise RuntimeError, "Ets.Record.lookup!/2 returned {:error, :multi_found}", fn ->
        Ets.Record.lookup!(:key, bag)
      end
    end

    test "lookup!/2 raises when missing table" do
      assert_raise RuntimeError, "Ets.Record.lookup!/2 returned {:error, :table_not_found}", fn ->
        Ets.Record.lookup!(:key, :not_a_table)
      end
    end
  end

  describe "Lookup Multi" do
    test "lookup_multi/2 returns nil on new table", %{bag: bag} do
      assert Ets.Record.lookup_multi(:key, bag) == {:ok, []}
    end

    test "lookup_multi/2 returns inserted value", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      assert Ets.Record.lookup_multi(:key, bag) == {:ok, [{:key, :a}]}
    end

    test "lookup_multi/2 returns multiple on multiple found", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      Ets.Record.insert({:key, :b}, bag)
      assert Ets.Record.lookup_multi(:key, bag) == {:ok, [{:key, :a}, {:key, :b}]}
    end

    test "lookup_multi/2 returns error on missing table" do
      assert Ets.Record.lookup_multi(:key, :not_a_table) == {:error, :table_not_found}
    end

    test "lookup_multi!/2 returns nil on new table", %{bag: bag} do
      assert Ets.Record.lookup_multi!(:key, bag) == []
    end

    test "lookup_multi!/2 returns inserted value", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      assert Ets.Record.lookup_multi!(:key, bag) == [{:key, :a}]
    end

    test "lookup_multi!/2 returns when multiple found", %{bag: bag} do
      Ets.Record.insert({:key, :a}, bag)
      Ets.Record.insert({:key, :b}, bag)

      assert Ets.Record.lookup_multi!(:key, bag) == [{:key, :a}, {:key, :b}]
    end

    test "lookup_multi!/2 raises when missing table" do
      assert_raise RuntimeError,
                   "Ets.Record.lookup_multi!/2 returned {:error, :table_not_found}",
                   fn ->
                     Ets.Record.lookup_multi!(:key, :not_a_table)
                   end
    end
  end

  describe "Match" do
    test "match/2 returns matches", %{bag: bag} do
      Ets.Record.insert({:key1, :a}, bag)
      Ets.Record.insert({:key2, :b}, bag)
      assert Ets.Record.match({:"$1", :b}, bag) == {:ok, [[:key2]]}
    end

    test "match/2 returns empty list on key not found", %{bag: bag} do
      assert Ets.Record.match({:"$1", :b}, bag) == {:ok, []}
    end

    test "match/2 returns error on missing table" do
      assert Ets.Record.match({:"$1", :b}, :not_a_table) == {:error, :table_not_found}
    end

    test "match!/2 returns matches", %{bag: bag} do
      Ets.Record.insert({:key1, :a}, bag)
      Ets.Record.insert({:key2, :b}, bag)
      assert Ets.Record.match!({:"$1", :b}, bag) == [[:key2]]
    end

    test "match!/2 returns empty list on key not found", %{bag: bag} do
      assert Ets.Record.match!({:"$1", :b}, bag) == []
    end

    test "match!/2 raises error on missing table" do
      assert_raise RuntimeError, "Ets.Record.match!/2 returned {:error, :table_not_found}", fn ->
        Ets.Record.match!({:"$1", :b}, :not_a_table)
      end
    end

    test "match/3 returns matches", %{bag: bag} do
      Ets.Record.insert({:key1, :a}, bag)
      Ets.Record.insert({:key2, :b}, bag)
      assert Ets.Record.match({:"$1", :b}, bag, 3) == {:ok, {[[:key2]], :end_of_table}}
    end

    test "match/3 returns empty list on key not found", %{bag: bag} do
      assert Ets.Record.match({:"$1", :b}, bag, 3) == {:ok, {[], :end_of_table}}
    end

    test "match/3 returns error on missing table" do
      assert Ets.Record.match({:"$1", :b}, :not_a_table) == {:error, :table_not_found}
    end

    test "match!/3 returns matches", %{bag: bag} do
      Ets.Record.insert({:key1, :a}, bag)
      Ets.Record.insert({:key2, :b}, bag)
      assert Ets.Record.match!({:"$1", :b}, bag, 3) == {[[:key2]], :end_of_table}
    end

    test "match!/3 returns empty list on key not found", %{bag: bag} do
      assert Ets.Record.match!({:"$1", :b}, bag, 3) == {[], :end_of_table}
    end

    test "match!/3 raises error on missing table" do
      assert_raise RuntimeError, "Ets.Record.match!/3 returned {:error, :table_not_found}", fn ->
        Ets.Record.match!({:"$1", :b}, :not_a_table, 3)
      end
    end
  end
end
