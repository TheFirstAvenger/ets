defmodule SetTest do
  use ExUnit.Case
  alias Ets.Set
  doctest Ets.Set

  describe "New" do
    test "Named Ordered Set" do
      name = table_name()
      assert %Set{} = Set.new!(name: name, ordered: true)
      assert %{name: ^name, named_table: true, type: :ordered_set} = table_info(name)
    end

    test "Named Set" do
      name = table_name()
      assert %Set{} = Set.new!(name: name)
      assert %{name: ^name, named_table: true, type: :set} = table_info(name)
    end

    test "Unnamed Ordered Set" do
      assert %Set{} = set = Set.new!(ordered: true)
      assert %{named_table: false, type: :ordered_set} = table_info(set)
    end

    test "Unnamed Set" do
      assert %Set{} = set = Set.new!()
      assert %{named_table: false, type: :set} = table_info(set)
    end

    test "rejects existing name" do
      name = table_name()
      assert %Set{} = Set.new!(name: name)

      assert_raise(RuntimeError, "Ets.Set.new!/1 returned {:error, :table_already_exists}", fn ->
        Set.new!(name: name)
      end)
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
    test "Ordered" do
      assert_raise RuntimeError,
                   "Ets.Set.new!/1 returned {:error, {:invalid_option, {:ordered, :this_isnt_a_boolean}}}",
                   fn ->
                     Set.new!(ordered: :this_isnt_a_boolean)
                   end
    end

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

  describe "Info" do
    test "returns correct information" do
      set = Set.new!(keypos: 4, read_concurrency: false, compressed: true)
      info = set |> Set.info!() |> Enum.into(%{})
      assert table_info(set) == info

      assert %{keypos: 4, read_concurrency: false, compressed: true} = info
    end

    test "force update flag" do
      set = Set.new!()
      memory = Set.info!(set)[:memory]

      1..10
      |> Enum.each(fn _ -> Set.put(set, {:rand.uniform(), :rand.uniform()}) end)

      assert memory == Set.info!(set)[:memory]
      assert memory != Set.info!(set, true)[:memory]
    end

    test "handles missing table" do
      set = Set.new!()
      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.info!/2 returned {:error, :table_not_found}", fn ->
        Set.info!(set, true)
      end
    end
  end

  describe "Get Table" do
    test "returns table" do
      table = :ets.new(nil, [:set])
      set = Set.wrap_existing!(table)
      assert table == Set.get_table!(set)
    end
  end

  describe "Put" do
    test "adds single entry to table" do
      set = Set.new!()
      assert [] == Set.to_list!(set)
      Set.put!(set, {:a, :b})
      assert [{:a, :b}] == Set.to_list!(set)
    end

    test "adds multiple entries to table" do
      set = Set.new!(ordered: true)
      assert [] == Set.to_list!(set)
      Set.put!(set, [{:a, :b}, {:c, :d}, {:e, :f}])
      assert [{:a, :b}, {:c, :d}, {:e, :f}] == Set.to_list!(set)
    end

    test "replaces existing entry" do
      set = Set.new!()
      assert [] == Set.to_list!(set)
      Set.put!(set, {:a, :b})
      assert [{:a, :b}] == Set.to_list!(set)
      Set.put!(set, {:a, :c})
      assert [{:a, :c}] == Set.to_list!(set)
    end

    test "raises on error" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :invalid_record}", fn ->
        Set.put!(set, [:a])
      end

      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :table_not_found}", fn ->
        Set.put!(set, {:a})
      end

      set2 = Set.new!(keypos: 3)

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :record_too_small}", fn ->
        Set.put!(set2, {:a, :b})
      end

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :record_too_small}", fn ->
        Set.put!(set2, [{:a, :b}, {:c}])
      end

      slf = self()

      spawn_link(fn ->
        set1 = Set.new!(protection: :protected)
        set2 = Set.new!(protection: :private)
        send(slf, {:table, set1, set2})
        :timer.sleep(:infinity)
      end)

      {set1, set2} =
        receive do
          {:table, set1, set2} -> {set1, set2}
        end

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :write_protected}", fn ->
        Set.put!(set1, {:a, :b, :c})
      end

      assert_raise RuntimeError, "Ets.Set.put!/2 returned {:error, :write_protected}", fn ->
        Set.put!(set2, {:a, :b, :c})
      end
    end
  end

  describe "Put New" do
    test "adds single entry to table" do
      set = Set.new!()
      assert [] == Set.to_list!(set)
      Set.put_new!(set, {:a, :b})
      assert [{:a, :b}] == Set.to_list!(set)
    end

    test "adds multiple entries to table" do
      set = Set.new!(ordered: true)
      assert [] == Set.to_list!(set)
      Set.put_new!(set, [{:a, :b}, {:c, :d}, {:e, :f}])
      assert [{:a, :b}, {:c, :d}, {:e, :f}] == Set.to_list!(set)
    end

    test "doesn't replace existing entry" do
      set = Set.new!()
      assert [] == Set.to_list!(set)
      Set.put_new!(set, {:a, :b})
      assert [{:a, :b}] == Set.to_list!(set)
      Set.put_new!(set, {:a, :c})
      assert [{:a, :b}] == Set.to_list!(set)
    end

    test "raises on error" do
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

      set2 = Set.new!(keypos: 3)

      assert_raise RuntimeError, "Ets.Set.put_new!/2 returned {:error, :record_too_small}", fn ->
        Set.put_new!(set2, {:a, :b})
      end

      assert_raise RuntimeError, "Ets.Set.put_new!/2 returned {:error, :record_too_small}", fn ->
        Set.put_new!(set2, [{:a, :b}, {:c}])
      end

      slf = self()

      spawn_link(fn ->
        set1 = Set.new!(protection: :protected)
        set2 = Set.new!(protection: :private)
        send(slf, {:table, set1, set2})
        :timer.sleep(:infinity)
      end)

      {set1, set2} =
        receive do
          {:table, set1, set2} -> {set1, set2}
        end

      assert_raise RuntimeError, "Ets.Set.put_new!/2 returned {:error, :write_protected}", fn ->
        Set.put_new!(set1, {:a, :b, :c})
      end

      assert_raise RuntimeError, "Ets.Set.put_new!/2 returned {:error, :write_protected}", fn ->
        Set.put_new!(set2, {:a, :b, :c})
      end
    end
  end

  describe "Get" do
    test "returns correct value" do
      set = Set.new!()
      Set.put(set, {:a, :b})
      assert {:a, :b} = Set.get!(set, :a)
    end

    test "returns correct value with default" do
      set = Set.new!()
      Set.put(set, {:a, :b})
      assert {:a, :b} = Set.get!(set, :a, :asdf)
    end

    test "returns nil when value missing" do
      set = Set.new!()
      assert nil == Set.get!(set, :a)
    end

    test "returns default when value missing and default specified" do
      set = Set.new!()
      assert :asdf == Set.get!(set, :a, :asdf)
    end

    test "raises on error" do
      set = Set.new!()
      Set.delete!(set)

      assert_raise RuntimeError, "Ets.Set.get!/3 returned {:error, :table_not_found}", fn ->
        Set.get!(set, :a)
      end

      slf = self()

      spawn_link(fn ->
        set = Set.new!(protection: :private)
        send(slf, {:table, set})
        :timer.sleep(:infinity)
      end)

      set =
        receive do
          {:table, set} -> set
        end

      assert_raise RuntimeError, "Ets.Set.get!/3 returned {:error, :read_protected}", fn ->
        Set.get!(set, :a)
      end
    end
  end

  describe "get_element" do
    test "returns correct elements" do
      set = Set.new!()
      Set.put!(set, {:a, :b, :c, :d})
      Set.put!(set, {:e, :f, :g, :h})
      assert :a = Set.get_element!(set, :a, 1)
      assert :b = Set.get_element!(set, :a, 2)
      assert :c = Set.get_element!(set, :a, 3)
      assert :d = Set.get_element!(set, :a, 4)
      assert :e = Set.get_element!(set, :e, 1)
      assert :f = Set.get_element!(set, :e, 2)
      assert :g = Set.get_element!(set, :e, 3)
      assert :h = Set.get_element!(set, :e, 4)
    end

    test "raises on error" do
      set = Set.new!()

      assert_raise RuntimeError, "Ets.Set.get_element!/3 returned {:error, :key_not_found}", fn ->
        Set.get_element!(set, :not_a_key, 2)
      end

      Set.put!(set, {:a, :b, :c, :d})

      assert_raise RuntimeError,
                   "Ets.Set.get_element!/3 returned {:error, :position_out_of_bounds}",
                   fn -> Set.get_element!(set, :a, 5) end

      Set.delete!(set)

      assert_raise RuntimeError,
                   "Ets.Set.get_element!/3 returned {:error, :table_not_found}",
                   fn -> Set.get_element!(set, :not_a_key, 2) end
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

  describe "Select" do
    test "select!/2 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.select!/2 returned {:error, :table_not_found}", fn ->
        Set.select!(set, [])
      end
    end

    test "select_delete!/2 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError,
                   "Ets.Set.select_delete!/2 returned {:error, :table_not_found}",
                   fn ->
                     Set.select_delete!(set, [])
                   end
    end

    test "select!/3 raises on error" do
      set = Set.new!()
      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.select!/3 returned {:error, :table_not_found}", fn ->
        Set.select!(set, [{[:"$"], [], [:"$_"]}], 10)
      end
    end

    test "select!/1 raises on error" do
      set = Set.new!()
      Set.put!(set, {1, "one"})
      Set.put!(set, {2, "two"})

      {_, continuation} = Set.select!(set, [{:_, [], [:"$_"]}], 1)

      Set.delete(set)

      assert_raise RuntimeError, "Ets.Set.select!/1 returned {:error, :table_not_found}", fn ->
        Set.select!(continuation)
      end
    end

    test "select!/3 continuation can be used with select!/1" do
      set = Set.new!()
      Set.put!(set, {1, "one"})
      Set.put!(set, {2, "two"})

      {[{2, "two"}], continuation} = Set.select!(set, [{:_, [], [:"$_"]}], 1)

      assert {[{1, "one"}], continuation} = Set.select!(continuation)

      assert :"$end_of_table" = Set.select!(continuation)
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

    test "delete_all!/1 raises on error" do
      set = Set.new!()
      Set.delete!(set)

      assert_raise RuntimeError,
                   "Ets.Set.delete_all!/1 returned {:error, :table_not_found}",
                   fn ->
                     Set.delete_all!(set)
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

  def table_name, do: String.to_atom("table#{:rand.uniform(9_999_999)}")

  def table_info(%Set{table: table}), do: table_info(table)

  def table_info(id) do
    id
    |> :ets.info()
    |> Enum.into(%{})
  end
end
