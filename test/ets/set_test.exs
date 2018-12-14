defmodule SetTest do
  use ExUnit.Case
  alias Ets.Set
  doctest Ets.Set

  describe "Named Tables Start" do
    test "Ordered Set" do
      name = table_name()
      assert %Set{} = Set.new!(name: name, ordered: true)
      assert %{name: ^name, named_table: true, type: :ordered_set} = table_info(name)
    end

    test "Set" do
      name = table_name()
      assert %Set{} = Set.new!(name: name)
      assert %{name: ^name, named_table: true, type: :set} = table_info(name)
    end
  end

  describe "Unnamed Tables Start" do
    test "Ordered Set" do
      assert %Set{} = set = Set.new!(ordered: true)
      assert %{named_table: false, type: :ordered_set} = table_info(set)
    end

    test "Set" do
      assert %Set{} = set = Set.new!()
      assert %{named_table: false, type: :set} = table_info(set)
    end
  end

  describe "Options set correctly" do
    test "Access" do
      assert %{protection: :private} = table_info(Set.new!(protection: :private))

      assert %{protection: :public} = table_info(Set.new!(protection: :public))

      assert %{protection: :protected} = table_info(Set.new!(protection: :protected))
    end

    test "Heir" do
      slf = self()
      assert %{heir: :none} = table_info(Set.new!(heir: :none))
      assert %{heir: ^slf} = table_info(Set.new!(heir: {slf, :some_data}))
    end

    test "Keypos" do
      assert %{keypos: 5} = table_info(Set.new!(keypos: 5))
      assert %{keypos: 55} = table_info(Set.new!(keypos: 55))
    end

    test "Read Concurrency" do
      assert %{read_concurrency: true} = table_info(Set.new!(read_concurrency: true))
      assert %{read_concurrency: false} = table_info(Set.new!(read_concurrency: false))
    end

    test "Write Concurrency" do
      assert %{write_concurrency: true} = table_info(Set.new!(write_concurrency: true))
      assert %{write_concurrency: false} = table_info(Set.new!(write_concurrency: false))
    end

    test "Compressed" do
      assert %{compressed: true} = table_info(Set.new!(compressed: true))
      assert %{compressed: false} = table_info(Set.new!(compressed: false))
    end
  end

  describe "Rejects bad options" do
    test "Access" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:protection, :nobody}}}",
                   fn ->
                     Set.new!(protection: :nobody)
                   end
    end

    test "Heir" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:heir, :nobody}}}",
                   fn ->
                     Set.new!(heir: :nobody)
                   end

      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:heir, {:not_a_pid, :data}}}}",
                   fn -> Set.new!(heir: {:not_a_pid, :data}) end
    end

    test "Keypos" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:keypos, -1}}}",
                   fn ->
                     Set.new!(keypos: -1)
                   end

      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:keypos, :not_a_number}}}",
                   fn ->
                     Set.new!(keypos: :not_a_number)
                   end
    end

    test "Read Concurrency" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:read_concurrency, :not_a_boolean}}}",
                   fn -> Set.new!(read_concurrency: :not_a_boolean) end
    end

    test "Write Concurrency" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:write_concurrency, :not_a_boolean}}}",
                   fn -> Set.new!(write_concurrency: :not_a_boolean) end
    end

    test "Compressed" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:compressed, :not_a_boolean}}}",
                   fn -> Set.new!(compressed: :not_a_boolean) end
    end
  end

  describe "Put" do
    test "put!/2 raises on error" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :invalid_record}", fn ->
        Set.put!(set, [:a])
      end

      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :table_not_found}", fn ->
        Set.put!(set, {:a})
      end
    end

    test "put_new!/2 raises on error" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.put_new!/2 returned {:error, :invalid_record}", fn ->
        Set.put_new!(set, [:a])
      end

      Set.delete!(set)

      assert_raise RuntimeError,
                   "Ets.Set.put_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Set.put_new!(set, {:a})
                   end
    end
  end

  describe "Match" do
    test "match!/2 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.match!/2 returned {:error, :table_not_found}", fn ->
        Set.match!(set, {:a})
      end
    end

    test "match!/3 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.match!/3 returned {:error, :table_not_found}", fn ->
        Set.match!(set, {:a}, 1)
      end
    end

    test "match!/1 raises on error" do
      assert_raise RuntimeError,
                   "Ets.Set.match!/1 returned {:error, :invalid_continuation}",
                   fn ->
                     Set.match!(:not_a_continuation)
                   end
    end
  end

  describe "Has Key" do
    test "has_key!/2 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.has_key!/2 returned {:error, :table_not_found}", fn ->
        Set.has_key!(set, :key)
      end
    end
  end

  describe "First" do
    test "first!/1 requires ordered set" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.first!/1 returned {:error, :set_not_ordered}", fn ->
        Set.first!(set)
      end
    end
  end

  describe "Last" do
    test "last!/1 requires ordered set" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.last!/1 returned {:error, :set_not_ordered}", fn ->
        Set.last!(set)
      end
    end
  end

  describe "Next" do
    test "next!/2 requires ordered set" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.next!/2 returned {:error, :set_not_ordered}", fn ->
        Set.next!(set, :a)
      end
    end
  end

  describe "Previous" do
    test "previous!/2 requires ordered set" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.previous!/2 returned {:error, :set_not_ordered}", fn ->
        Set.previous!(set, :a)
      end
    end
  end

  describe "To List" do
    test "to_list!/1 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.to_list!/1 returned {:error, :table_not_found}", fn ->
        Set.to_list!(set)
      end
    end
  end

  describe "Delete" do
    test "delete!/2 raises on error" do
      set = Set.new!()
      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.delete!/1 returned {:error, :table_not_found}", fn ->
        Set.delete!(set)
      end
    end

    test "delete!/1 raises on error" do
      set = Set.new!()
      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.delete!/2 returned {:error, :table_not_found}", fn ->
        Set.delete!(set, :a)
      end
    end
  end

  describe "Wrap Existing" do
    test "wrap_existing!/1 raises on error" do
      assert_raise RuntimeError,
                   "Ets.Set.wrap_existing!/1 returned {:error, :table_not_found}",
                   fn ->
                     Set.wrap_existing!(:not_a_table)
                   end
    end
  end

  describe "Get Table" do
    test "get_table!/1 returns table" do
      table = :ets.new(nil, [:set])
      set = Set.wrap_existing!(table)
      assert table == Set.get_table!(set)
    end
  end

  def table_name, do: String.to_atom("table#{:rand.uniform(9_999_999)}")

  def table_info(%Set{table: table}), do: table_info(table)

  def table_info(id) do
    id
    |> :ets.info()
    |> Enum.into(%{})
  end
end
