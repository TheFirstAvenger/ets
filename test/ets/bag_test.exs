defmodule BagTest do
  use ExUnit.Case
  alias Ets.Bag
  doctest Ets.Bag

  describe "Named Tables Start" do
    test "Duplicate Bag" do
      name = table_name()
      assert %Bag{} = Bag.new!(name: name)
      assert %{name: ^name, named_table: true, type: :duplicate_bag} = table_info(name)
    end

    test "Bag" do
      name = table_name()
      assert %Bag{} = Bag.new!(name: name, duplicate: false)
      assert %{name: ^name, named_table: true, type: :bag} = table_info(name)
    end
  end

  describe "Unnamed Tables Start" do
    test "Duplicate Bag" do
      assert %Bag{} = bag = Bag.new!()
      assert %{named_table: false, type: :duplicate_bag} = table_info(bag)
    end

    test "Bag" do
      assert %Bag{} = bag = Bag.new!(duplicate: false)
      assert %{named_table: false, type: :bag} = table_info(bag)
    end
  end

  describe "Options bag correctly" do
    test "Access" do
      assert %{protection: :private} = table_info(Bag.new!(protection: :private))

      assert %{protection: :public} = table_info(Bag.new!(protection: :public))

      assert %{protection: :protected} = table_info(Bag.new!(protection: :protected))
    end

    test "Heir" do
      slf = self()
      assert %{heir: :none} = table_info(Bag.new!(heir: :none))
      assert %{heir: ^slf} = table_info(Bag.new!(heir: {slf, :some_data}))
    end

    test "Keypos" do
      assert %{keypos: 5} = table_info(Bag.new!(keypos: 5))
      assert %{keypos: 55} = table_info(Bag.new!(keypos: 55))
    end

    test "Read Concurrency" do
      assert %{read_concurrency: true} = table_info(Bag.new!(read_concurrency: true))
      assert %{read_concurrency: false} = table_info(Bag.new!(read_concurrency: false))
    end

    test "Write Concurrency" do
      assert %{write_concurrency: true} = table_info(Bag.new!(write_concurrency: true))
      assert %{write_concurrency: false} = table_info(Bag.new!(write_concurrency: false))
    end

    test "Compressed" do
      assert %{compressed: true} = table_info(Bag.new!(compressed: true))
      assert %{compressed: false} = table_info(Bag.new!(compressed: false))
    end
  end

  describe "Rejects bad options" do
    test "Duplicate" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:duplicate, :this_isnt_a_boolean}}}",
                   fn ->
                     Bag.new!(duplicate: :this_isnt_a_boolean)
                   end
    end

    test "Access" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:protection, :nobody}}}",
                   fn ->
                     Bag.new!(protection: :nobody)
                   end
    end

    test "Heir" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:heir, :nobody}}}",
                   fn ->
                     Bag.new!(heir: :nobody)
                   end

      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:heir, {:not_a_pid, :data}}}}",
                   fn -> Bag.new!(heir: {:not_a_pid, :data}) end
    end

    test "Keypos" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:keypos, -1}}}",
                   fn ->
                     Bag.new!(keypos: -1)
                   end

      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:keypos, :not_a_number}}}",
                   fn ->
                     Bag.new!(keypos: :not_a_number)
                   end
    end

    test "Read Concurrency" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:read_concurrency, :not_a_boolean}}}",
                   fn -> Bag.new!(read_concurrency: :not_a_boolean) end
    end

    test "Write Concurrency" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:write_concurrency, :not_a_boolean}}}",
                   fn -> Bag.new!(write_concurrency: :not_a_boolean) end
    end

    test "Compressed" do
      assert_raise RuntimeError,
                   "Ets.Bag.new!/1 returned {:error, {:invalid_option, {:compressed, :not_a_boolean}}}",
                   fn -> Bag.new!(compressed: :not_a_boolean) end
    end
  end

  describe "Add" do
    test "add!/2 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError, "Ets.Bag.add!/2 returned {:error, :invalid_record}", fn ->
        Bag.add!(bag, [:a])
      end

      Bag.delete!(bag)

      assert_raise RuntimeError, "Ets.Bag.add!/2 returned {:error, :table_not_found}", fn ->
        Bag.add!(bag, {:a})
      end
    end

    test "add_new!/2 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError, "Ets.Bag.add_new!/2 returned {:error, :invalid_record}", fn ->
        Bag.add_new!(bag, [:a])
      end

      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "Ets.Bag.add_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.add_new!(bag, {:a})
                   end
    end
  end

  describe "Lookup" do
    test "lookup_element!/3 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError,
                   "Ets.Bag.lookup_element!/3 returned {:error, :key_not_found}",
                   fn ->
                     Bag.lookup_element!(bag, :not_a_key, 2)
                   end

      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "Ets.Bag.lookup_element!/3 returned {:error, :table_not_found}",
                   fn -> Bag.lookup_element!(bag, :not_a_key, 2) end
    end
  end

  describe "Match" do
    test "match!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "Ets.Bag.match!/2 returned {:error, :table_not_found}", fn ->
        Bag.match!(bag, {:a})
      end
    end

    test "match!/3 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "Ets.Bag.match!/3 returned {:error, :table_not_found}", fn ->
        Bag.match!(bag, {:a}, 1)
      end
    end

    test "match!/1 raises on error" do
      assert_raise RuntimeError,
                   "Ets.Bag.match!/1 returned {:error, :invalid_continuation}",
                   fn ->
                     Bag.match!(:not_a_continuation)
                   end
    end
  end

  describe "Select" do
    test "select!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "Ets.Bag.select!/2 returned {:error, :table_not_found}", fn ->
        Bag.select!(bag, [])
      end
    end

    test "select_delete!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError,
                   "Ets.Bag.select_delete!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.select_delete!(bag, [])
                   end
    end
  end

  describe "Has Key" do
    test "has_key!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "Ets.Bag.has_key!/2 returned {:error, :table_not_found}", fn ->
        Bag.has_key!(bag, :key)
      end
    end
  end

  describe "To List" do
    test "to_list!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "Ets.Bag.to_list!/1 returned {:error, :table_not_found}", fn ->
        Bag.to_list!(bag)
      end
    end
  end

  describe "Delete" do
    test "delete!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError, "Ets.Bag.delete!/1 returned {:error, :table_not_found}", fn ->
        Bag.delete!(bag)
      end
    end

    test "delete!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError, "Ets.Bag.delete!/2 returned {:error, :table_not_found}", fn ->
        Bag.delete!(bag, :a)
      end
    end

    test "delete_all!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "Ets.Bag.delete_all!/1 returned {:error, :table_not_found}",
                   fn ->
                     Bag.delete_all!(bag)
                   end
    end
  end

  describe "Wrap Existing" do
    test "wrap_existing!/1 raises on error" do
      assert_raise RuntimeError,
                   "Ets.Bag.wrap_existing!/1 returned {:error, :table_not_found}",
                   fn ->
                     Bag.wrap_existing!(:not_a_table)
                   end
    end
  end

  describe "Get Table" do
    test "get_table!/1 returns table" do
      table = :ets.new(nil, [:bag])
      bag = Bag.wrap_existing!(table)
      assert table == Bag.get_table!(bag)
    end
  end

  def table_name, do: String.to_atom("table#{:rand.uniform(9_999_999)}")

  def table_info(%Bag{table: table}), do: table_info(table)

  def table_info(id) do
    id
    |> :ets.info()
    |> Enum.into(%{})
  end
end
