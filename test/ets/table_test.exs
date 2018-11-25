defmodule EtsTableTest do
  use ExUnit.Case
  doctest Ets.Table

  describe "All" do
    test "all/0 returns list of tables including created tables" do
      Ets.Table.New.bag(:abc)
      Ets.Table.New.bag(:def)
      Ets.Table.New.bag(:ghi)
      ref1 = Ets.Table.New.bag!()
      ref2 = Ets.Table.New.bag!()
      ref3 = Ets.Table.New.bag!()
      {:ok, tables} = Ets.Table.all()
      assert Enum.member?(tables, :abc)
      assert Enum.member?(tables, :def)
      assert Enum.member?(tables, :ghi)
      assert Enum.member?(tables, ref1)
      assert Enum.member?(tables, ref2)
      assert Enum.member?(tables, ref3)
    end

    test "all/0 doesn't include missing tables" do
      {:ok, tables} = Ets.Table.all()
      refute Enum.member?(tables, :asdfasdf)
      refute Enum.member?(tables, self())
    end

    test "all/0 doesn't include deleted tables" do
      Ets.Table.New.set!(:my_ets_table)
      {:ok, tables} = Ets.Table.all()
      assert Enum.member?(tables, :my_ets_table)
      Ets.Table.delete!(:my_ets_table)
      {:ok, tables} = Ets.Table.all()
      refute Enum.member?(tables, :my_ets_table)
    end

    test "all!/0 returns list of tables including created tables" do
      Ets.Table.New.bag(:abc)
      Ets.Table.New.bag(:def)
      Ets.Table.New.bag(:ghi)
      ref1 = Ets.Table.New.bag!()
      ref2 = Ets.Table.New.bag!()
      ref3 = Ets.Table.New.bag!()
      tables = Ets.Table.all!()
      assert Enum.member?(tables, :abc)
      assert Enum.member?(tables, :def)
      assert Enum.member?(tables, :ghi)
      assert Enum.member?(tables, ref1)
      assert Enum.member?(tables, ref2)
      assert Enum.member?(tables, ref3)
    end

    test "all!/0 doesn't include missing tables" do
      tables = Ets.Table.all!()
      refute Enum.member?(tables, :asdfasdf)
      refute Enum.member?(tables, self())
    end

    test "all!/0 doesn't include deleted tables" do
      Ets.Table.New.set!(:my_ets_table)
      assert Enum.member?(Ets.Table.all!(), :my_ets_table)
      Ets.Table.delete!(:my_ets_table)
      refute Enum.member?(Ets.Table.all!(), :my_ets_table)
    end
  end

  describe "Delete" do
    test "delete/1 deletes table" do
      Ets.Table.New.set(:my_ets_table)
      assert Enum.member?(Ets.Table.all!(), :my_ets_table)
      assert {:ok, :my_ets_table} = Ets.Table.delete(:my_ets_table)
      refute Enum.member?(Ets.Table.all!(), :my_ets_table)
    end

    test "delete/1 returns error on missing table" do
      assert {:error, :table_not_found} = Ets.Table.delete(:not_a_table)
    end

    test "delete!/1 deletes table" do
      Ets.Table.New.set(:my_ets_table)
      assert Enum.member?(Ets.Table.all!(), :my_ets_table)
      assert :my_ets_table = Ets.Table.delete!(:my_ets_table)
      refute Enum.member?(Ets.Table.all!(), :my_ets_table)
    end

    test "delete!/1 returns error on missing table" do
      assert_raise RuntimeError, "Ets.Table.delete!/1 returned {:error, :table_not_found}", fn ->
        Ets.Table.delete!(:not_a_table)
      end
    end
  end

  describe "Info" do
    test "info/1 returns information on found table" do
      table = Ets.Table.New.bag!()
      {:ok, info} = Ets.Table.info(table)
      assert info[:name] == nil
      assert info[:named_table] == false
      assert info[:type] == :bag
      assert info[:keypos] == 1
      assert info[:protection] == :protected
    end

    test "info/1 returns error on missing table" do
      assert Ets.Table.info(:not_a_table) == {:error, :table_not_found}
    end

    test "info!/1 returns information on found table" do
      table = Ets.Table.New.bag!()
      info = Ets.Table.info!(table)
      assert info[:name] == nil
      assert info[:named_table] == false
      assert info[:type] == :bag
      assert info[:keypos] == 1
      assert info[:protection] == :protected
    end

    test "info!/1 raises error on missing table" do
      assert_raise RuntimeError,
                   "Ets.Table.info!/1 returned {:error, :table_not_found}",
                   fn -> Ets.Table.info!(:not_a_table) end
    end
  end

  describe "Rename" do
    test "rename/2 updates table name" do
      Ets.Table.New.set(:my_ets_table)
      ref = Ets.Table.info!(:my_ets_table)[:id]
      assert {:ok, :new_name} == Ets.Table.rename(:new_name, :my_ets_table)
      assert ref == Ets.Table.info!(:new_name)[:id]
    end

    test "rename/2 returns error on missing table" do
      assert {:error, :table_not_found} == Ets.Table.rename(:aa, :not_a_table)
    end

    test "rename!/2 updates table name" do
      Ets.Table.New.set(:my_ets_table)
      ref = Ets.Table.info!(:my_ets_table)[:id]
      assert :new_name = Ets.Table.rename!(:new_name, :my_ets_table)
      assert ref == Ets.Table.info!(:new_name)[:id]
    end

    test "rename!/2 returns error on missing table" do
      assert_raise RuntimeError, "Ets.Table.rename!/2 returned {:error, :table_not_found}", fn ->
        Ets.Table.rename!(:aa, :not_a_table)
      end
    end
  end

  describe "To List" do
    test "to_list/1 returns data from found table" do
      table = Ets.Table.New.bag!()
      vals = [{:a, :b}, {:c, :d}, {:e, :f}, {:g, :h}]
      Ets.insert_multi!(vals, table)
      assert Ets.Table.to_list(table) == {:ok, [{:g, :h}, {:e, :f}, {:c, :d}, {:a, :b}]}
    end

    test "to_list/1 returns error on missing table" do
      assert Ets.Table.to_list(:not_a_table) == {:error, :table_not_found}
    end

    test "to_list!/1 returns data from found table" do
      table = Ets.Table.New.bag!()
      vals = [{:a, :b}, {:c, :d}, {:e, :f}, {:g, :h}]
      Ets.insert_multi!(vals, table)
      assert Ets.Table.to_list!(table) == [{:g, :h}, {:e, :f}, {:c, :d}, {:a, :b}]
    end

    test "to_list!/1 raises error on missing table" do
      assert_raise RuntimeError,
                   "Ets.Table.to_list!/1 returned {:error, :table_not_found}",
                   fn -> Ets.Table.to_list!(:not_a_table) end
    end
  end

  describe "Whereis" do
    test "whereis/1 returns reference on found table" do
      Ets.Table.New.set(:my_ets_table)
      info = Ets.Table.info!(:my_ets_table)
      ref = info[:id]
      assert {:ok, ^ref} = Ets.Table.whereis(:my_ets_table)
    end

    test "whereis/1 returns error on missing table" do
      assert Ets.Table.whereis(:not_a_table) == {:error, :table_not_found}
    end

    test "whereis!/1 returns reference on found table" do
      Ets.Table.New.set(:my_ets_table)
      info = Ets.Table.info!(:my_ets_table)
      ref = info[:id]
      assert ^ref = Ets.Table.whereis!(:my_ets_table)
    end

    test "whereis!/1 raises on missing table" do
      assert_raise RuntimeError,
                   "Ets.Table.whereis!/1 returned {:error, :table_not_found}",
                   fn -> Ets.Table.whereis!(:not_a_table) end
    end
  end
end
