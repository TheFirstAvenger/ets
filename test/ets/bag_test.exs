defmodule BagTest do
  use ExUnit.Case

  alias ETS.Bag
  alias ETS.TestUtils

  doctest ETS.Bag

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

      if ETS.TestUtils.otp25?() do
        assert %{write_concurrency: :auto} = table_info(Bag.new!(write_concurrency: :auto))
      end
    end

    test "Compressed" do
      assert %{compressed: true} = table_info(Bag.new!(compressed: true))
      assert %{compressed: false} = table_info(Bag.new!(compressed: false))
    end
  end

  describe "Rejects bad options" do
    test "Duplicate" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:duplicate, :this_isnt_a_boolean}}}",
                   fn ->
                     Bag.new!(duplicate: :this_isnt_a_boolean)
                   end
    end

    test "Access" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:protection, :nobody}}}",
                   fn ->
                     Bag.new!(protection: :nobody)
                   end
    end

    test "Heir" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:heir, :nobody}}}",
                   fn ->
                     Bag.new!(heir: :nobody)
                   end

      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:heir, {:not_a_pid, :data}}}}",
                   fn -> Bag.new!(heir: {:not_a_pid, :data}) end
    end

    test "Keypos" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:keypos, -1}}}",
                   fn ->
                     Bag.new!(keypos: -1)
                   end

      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:keypos, :not_a_number}}}",
                   fn ->
                     Bag.new!(keypos: :not_a_number)
                   end
    end

    test "Read Concurrency" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:read_concurrency, :not_a_boolean}}}",
                   fn -> Bag.new!(read_concurrency: :not_a_boolean) end
    end

    test "Write Concurrency" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:write_concurrency, :not_a_boolean}}}",
                   fn -> Bag.new!(write_concurrency: :not_a_boolean) end
    end

    test "Compressed" do
      assert_raise RuntimeError,
                   "ETS.Bag.new!/1 returned {:error, {:invalid_option, {:compressed, :not_a_boolean}}}",
                   fn -> Bag.new!(compressed: :not_a_boolean) end
    end
  end

  describe "Add" do
    test "add!/2 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError, "ETS.Bag.add!/2 returned {:error, :invalid_record}", fn ->
        Bag.add!(bag, [:a])
      end

      Bag.delete!(bag)

      assert_raise RuntimeError, "ETS.Bag.add!/2 returned {:error, :table_not_found}", fn ->
        Bag.add!(bag, {:a})
      end

      bag2 = Bag.new!(keypos: 3)

      assert_raise RuntimeError, "ETS.Bag.add!/2 returned {:error, :record_too_small}", fn ->
        Bag.add!(bag2, {:a, :b})
      end

      assert_raise RuntimeError, "ETS.Bag.add!/2 returned {:error, :record_too_small}", fn ->
        Bag.add!(bag2, [{:a, :b}, {:c}])
      end
    end

    test "add_new!/2 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError, "ETS.Bag.add_new!/2 returned {:error, :invalid_record}", fn ->
        Bag.add_new!(bag, [:a])
      end

      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.add_new!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.add_new!(bag, {:a})
                   end

      bag2 = Bag.new!(keypos: 3)

      assert_raise RuntimeError, "ETS.Bag.add_new!/2 returned {:error, :record_too_small}", fn ->
        Bag.add_new!(bag2, {:a, :b})
      end

      assert_raise RuntimeError, "ETS.Bag.add_new!/2 returned {:error, :record_too_small}", fn ->
        Bag.add_new!(bag2, [{:a, :b}, {:c}])
      end
    end
  end

  describe "Lookup" do
    test "lookup_element!/3 raises on error" do
      bag = Bag.new!()

      assert_raise RuntimeError,
                   "ETS.Bag.lookup_element!/3 returned {:error, :key_not_found}",
                   fn ->
                     Bag.lookup_element!(bag, :not_a_key, 2)
                   end

      Bag.add!(bag, {:a, :b, :c, :d, :e})
      Bag.add!(bag, {:a, :e, :f, :g})

      assert_raise RuntimeError,
                   "ETS.Bag.lookup_element!/3 returned {:error, :position_out_of_bounds}",
                   fn -> Bag.lookup_element!(bag, :a, 5) end

      assert_raise RuntimeError,
                   "ETS.Bag.lookup_element!/3 returned {:error, :position_out_of_bounds}",
                   fn -> Bag.lookup_element!(bag, :a, 6) end

      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.lookup_element!/3 returned {:error, :table_not_found}",
                   fn -> Bag.lookup_element!(bag, :not_a_key, 2) end
    end
  end

  describe "Match" do
    test "match!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "ETS.Bag.match!/2 returned {:error, :table_not_found}", fn ->
        Bag.match!(bag, {:a})
      end
    end

    test "match!/3 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "ETS.Bag.match!/3 returned {:error, :table_not_found}", fn ->
        Bag.match!(bag, {:a}, 1)
      end
    end

    test "match!/1 raises on error" do
      assert_raise RuntimeError,
                   "ETS.Bag.match!/1 returned {:error, :invalid_continuation}",
                   fn ->
                     Bag.match!(:not_a_continuation)
                   end
    end

    test "match_delete!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.match_delete!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.match_delete!(bag, {:a})
                   end
    end

    test "match_object!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.match_object!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.match_object!(bag, {:a})
                   end
    end

    test "match_object/3 reaches end of table" do
      bag = Bag.new!()
      Bag.add!(bag, {:w, :x, :y, :z})
      assert {:ok, {[], :end_of_table}} = Bag.match_object(bag, {:_, :b, :_, :_}, 1)

      Bag.add!(bag, {:a, :b, :c, :d})
      assert {:ok, {results, :end_of_table}} = Bag.match_object(bag, {:"$1", :b, :"$2", :_}, 2)
      assert results == [{:a, :b, :c, :d}]
    end

    test "match_object!/3 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.match_object!/3 returned {:error, :table_not_found}",
                   fn ->
                     Bag.match_object!(bag, {:a}, 1)
                   end
    end

    test "match_object/1 finds less matches than the limit" do
      bag = Bag.new!()
      Bag.add!(bag, [{:a, :b, :c, :d}, {:a, :b, :e, :f}, {:g, :b, :h, :i}])
      {:ok, {_result, continuation}} = Bag.match_object(bag, {:_, :b, :_, :_}, 2)

      assert {:ok, {results, :end_of_table}} = Bag.match_object(continuation)
      assert results == [{:g, :b, :h, :i}]
    end

    test "match_object!/1 raises on error" do
      assert_raise RuntimeError,
                   "ETS.Bag.match_object!/1 returned {:error, :invalid_continuation}",
                   fn ->
                     Bag.match_object!(:not_a_continuation)
                   end
    end
  end

  describe "Select" do
    test "select!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "ETS.Bag.select!/2 returned {:error, :table_not_found}", fn ->
        Bag.select!(bag, [])
      end
    end

    test "select_delete!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.select_delete!/2 returned {:error, :table_not_found}",
                   fn ->
                     Bag.select_delete!(bag, [])
                   end
    end
  end

  describe "Has Key" do
    test "has_key!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "ETS.Bag.has_key!/2 returned {:error, :table_not_found}", fn ->
        Bag.has_key!(bag, :key)
      end
    end
  end

  describe "To List" do
    test "to_list!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete(bag)

      assert_raise RuntimeError, "ETS.Bag.to_list!/1 returned {:error, :table_not_found}", fn ->
        Bag.to_list!(bag)
      end
    end
  end

  describe "Delete" do
    test "delete!/2 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError, "ETS.Bag.delete!/1 returned {:error, :table_not_found}", fn ->
        Bag.delete!(bag)
      end
    end

    test "delete!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError, "ETS.Bag.delete!/2 returned {:error, :table_not_found}", fn ->
        Bag.delete!(bag, :a)
      end
    end

    test "delete_all!/1 raises on error" do
      bag = Bag.new!()
      Bag.delete!(bag)

      assert_raise RuntimeError,
                   "ETS.Bag.delete_all!/1 returned {:error, :table_not_found}",
                   fn ->
                     Bag.delete_all!(bag)
                   end
    end
  end

  describe "Wrap Existing" do
    test "wrap_existing!/1 raises on error" do
      assert_raise RuntimeError,
                   "ETS.Bag.wrap_existing!/1 returned {:error, :table_not_found}",
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

  describe "Give Away give_away!/3" do
    test "success" do
      recipient_pid = self()

      spawn(fn ->
        bag = Bag.new!()
        Bag.give_away!(bag, recipient_pid)
      end)

      assert {:ok, %{bag: %Bag{}, gift: []}} = Bag.accept()
    end

    test "timeout" do
      assert {:error, :timeout} = Bag.accept(10)
    end

    test "cannot give to process which already owns table" do
      assert_raise RuntimeError,
                   "ETS.Bag.give_away!/3 returned {:error, :recipient_already_owns_table}",
                   fn ->
                     bag = Bag.new!()
                     Bag.give_away!(bag, self())
                   end
    end

    test "cannot give to process which is not alive" do
      assert_raise RuntimeError,
                   "ETS.Bag.give_away!/3 returned {:error, :recipient_not_alive}",
                   fn ->
                     bag = Bag.new!()
                     Bag.give_away!(bag, TestUtils.dead_pid())
                   end
    end

    test "cannot give a table belonging to another process" do
      sender_pid = self()

      _owner_pid =
        spawn_link(fn ->
          bag = Bag.new!()
          send(sender_pid, bag)
          Process.sleep(:infinity)
        end)

      assert_receive bag

      recipient_pid = spawn_link(fn -> Process.sleep(:infinity) end)

      assert_raise RuntimeError,
                   "ETS.Bag.give_away!/3 returned {:error, :sender_not_table_owner}",
                   fn ->
                     Bag.give_away!(bag, recipient_pid)
                   end
    end
  end

  describe "Macro" do
    test "accept/5 success" do
      {:ok, recipient_pid} = start_supervised(ETS.TestServer)

      %Bag{table: table} = bag = Bag.new!()

      Bag.give_away!(bag, recipient_pid, :bag_test)

      assert_receive {:thank_you, %Bag{table: ^table}}
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
