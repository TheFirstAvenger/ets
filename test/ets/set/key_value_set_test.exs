defmodule KeyValueSetTest do
  use ExUnit.Case

  alias ETS.KeyValueSet
  alias ETS.Set
  alias ETS.TestUtils

  doctest ETS.KeyValueSet

  describe "New" do
    test "Named Ordered KeyValueSet" do
      name = table_name()
      assert %KeyValueSet{} = KeyValueSet.new!(name: name, ordered: true)
      assert %{name: ^name, named_table: true, type: :ordered_set} = table_info(name)
    end

    test "Named KeyValueSet" do
      name = table_name()
      assert %KeyValueSet{} = KeyValueSet.new!(name: name)
      assert %{name: ^name, named_table: true, type: :set} = table_info(name)
    end

    test "Unnamed Ordered KeyValueSet" do
      assert %KeyValueSet{} = set = KeyValueSet.new!(ordered: true)
      assert %{named_table: false, type: :ordered_set} = table_info(set)
    end

    test "Unnamed KeyValueSet" do
      assert %KeyValueSet{} = set = KeyValueSet.new!()
      assert %{named_table: false, type: :set} = table_info(set)
    end

    test "rejects existing name" do
      name = table_name()
      assert %KeyValueSet{} = KeyValueSet.new!(name: name)

      assert_raise(
        RuntimeError,
        "ETS.KeyValueSet.new!/1 returned {:error, :table_already_exists}",
        fn ->
          KeyValueSet.new!(name: name)
        end
      )
    end
  end

  describe "Options set correctly" do
    test "Access" do
      assert %{protection: :private} = table_info(KeyValueSet.new!(protection: :private))

      assert %{protection: :public} = table_info(KeyValueSet.new!(protection: :public))

      assert %{protection: :protected} = table_info(KeyValueSet.new!(protection: :protected))
    end

    test "Heir" do
      slf = self()
      assert %{heir: :none} = table_info(KeyValueSet.new!(heir: :none))
      assert %{heir: ^slf} = table_info(KeyValueSet.new!(heir: {slf, :some_data}))
    end

    test "Read Concurrency" do
      assert %{read_concurrency: true} = table_info(KeyValueSet.new!(read_concurrency: true))
      assert %{read_concurrency: false} = table_info(KeyValueSet.new!(read_concurrency: false))
    end

    test "Write Concurrency" do
      assert %{write_concurrency: true} = table_info(KeyValueSet.new!(write_concurrency: true))
      assert %{write_concurrency: false} = table_info(KeyValueSet.new!(write_concurrency: false))

      if ETS.TestUtils.otp25?() do
        assert %{write_concurrency: :auto} =
                 table_info(KeyValueSet.new!(write_concurrency: :auto))
      end
    end

    test "Compressed" do
      assert %{compressed: true} = table_info(KeyValueSet.new!(compressed: true))
      assert %{compressed: false} = table_info(KeyValueSet.new!(compressed: false))
    end
  end

  describe "Rejects bad options" do
    test "Ordered" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:ordered, :this_isnt_a_boolean}}}",
                   fn ->
                     KeyValueSet.new!(ordered: :this_isnt_a_boolean)
                   end
    end

    test "Access" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:protection, :nobody}}}",
                   fn ->
                     KeyValueSet.new!(protection: :nobody)
                   end
    end

    test "Heir" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:heir, :nobody}}}",
                   fn ->
                     KeyValueSet.new!(heir: :nobody)
                   end

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:heir, {:not_a_pid, :data}}}}",
                   fn -> KeyValueSet.new!(heir: {:not_a_pid, :data}) end
    end

    test "Keypos" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:keypos, -1}}}",
                   fn ->
                     KeyValueSet.new!(keypos: -1)
                   end

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:keypos, 3}}}",
                   fn ->
                     KeyValueSet.new!(keypos: 3)
                   end

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:keypos, :this_is_not_a_number}}}",
                   fn ->
                     KeyValueSet.new!(keypos: :this_is_not_a_number)
                   end

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:keypos, 1}}}",
                   fn ->
                     KeyValueSet.new!(keypos: 1)
                   end
    end

    test "Read Concurrency" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:read_concurrency, :not_a_boolean}}}",
                   fn -> KeyValueSet.new!(read_concurrency: :not_a_boolean) end
    end

    test "Write Concurrency" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:write_concurrency, :not_a_boolean}}}",
                   fn -> KeyValueSet.new!(write_concurrency: :not_a_boolean) end
    end

    test "Compressed" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.new!/1 returned {:error, {:invalid_option, {:compressed, :not_a_boolean}}}",
                   fn -> KeyValueSet.new!(compressed: :not_a_boolean) end
    end
  end

  describe "Wrap existing" do
    test "Rejects not a set" do
      table = :ets.new(nil, [:bag])

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.wrap_existing!/1 returned {:error, :invalid_type}",
                   fn -> KeyValueSet.wrap_existing!(table) end
    end

    test "Rejects invalid keypos" do
      table = :ets.new(nil, [:set, keypos: 2])

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.wrap_existing!/1 returned {:error, :invalid_keypos}",
                   fn -> KeyValueSet.wrap_existing!(table) end
    end

    test "Succeeds on valid table" do
      table = :ets.new(nil, [:set])
      kvset = KeyValueSet.wrap_existing!(table)
      assert KeyValueSet.info!(kvset)[:id] == table
    end
  end

  describe "Info" do
    test "returns correct information" do
      set = KeyValueSet.new!(read_concurrency: false, compressed: true)
      info = set |> KeyValueSet.info!() |> Enum.into(%{})
      assert table_info(set) == info

      assert %{read_concurrency: false, compressed: true} = info
    end

    test "returns correct information (tuple version)" do
      set = KeyValueSet.new!(read_concurrency: false, compressed: true)
      {:ok, info} = KeyValueSet.info(set)
      info = info |> Enum.into(%{})
      assert table_info(set) == info

      assert %{read_concurrency: false, compressed: true} = info
    end

    test "force update flag" do
      set = KeyValueSet.new!()
      memory = KeyValueSet.info!(set)[:memory]

      1..10
      |> Enum.each(fn _ -> KeyValueSet.put(set, :rand.uniform(), :rand.uniform()) end)

      assert memory == KeyValueSet.info!(set)[:memory]
      assert memory != KeyValueSet.info!(set, true)[:memory]
    end

    test "handles missing table" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.info!/2 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.info!(set, true)
                   end
    end
  end

  describe "Get Table" do
    test "returns table" do
      table = :ets.new(nil, [:set])
      set = KeyValueSet.wrap_existing!(table)
      assert table == KeyValueSet.get_table!(set)
    end
  end

  describe "Put" do
    test "adds single entry to table" do
      set = KeyValueSet.new!()
      assert [] == KeyValueSet.to_list!(set)
      KeyValueSet.put!(set, :a, :b)
      assert [{:a, :b}] == KeyValueSet.to_list!(set)
    end

    test "replaces existing entry" do
      set = KeyValueSet.new!()
      assert [] == KeyValueSet.to_list!(set)
      KeyValueSet.put!(set, :a, :b)
      assert [{:a, :b}] == KeyValueSet.to_list!(set)
      KeyValueSet.put!(set, :a, :c)
      assert [{:a, :c}] == KeyValueSet.to_list!(set)
    end

    test "raises on error" do
      set = KeyValueSet.new!()

      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.put!/3 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.put!(set, :a, :b)
                   end
    end
  end

  describe "Put New" do
    test "adds single entry to table" do
      set = KeyValueSet.new!()
      assert [] == KeyValueSet.to_list!(set)
      KeyValueSet.put_new!(set, :a, :b)
      assert [{:a, :b}] == KeyValueSet.to_list!(set)
    end

    test "doesn't replace existing entry" do
      set = KeyValueSet.new!()
      assert [] == KeyValueSet.to_list!(set)
      KeyValueSet.put_new!(set, :a, :b)
      assert [{:a, :b}] == KeyValueSet.to_list!(set)
      KeyValueSet.put_new!(set, :a, :c)
      assert [{:a, :b}] == KeyValueSet.to_list!(set)
    end

    test "raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.put_new!/3 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.put_new!(set, :a, :b)
                   end
    end
  end

  describe "Get" do
    test "returns correct value" do
      set = KeyValueSet.new!()
      KeyValueSet.put(set, :a, :b)
      assert :b = KeyValueSet.get!(set, :a)
    end

    test "returns correct value with default" do
      set = KeyValueSet.new!()
      KeyValueSet.put(set, :a, :b)
      assert :b = KeyValueSet.get!(set, :a, :asdf)
    end

    test "returns nil when value missing" do
      set = KeyValueSet.new!()
      assert nil == KeyValueSet.get!(set, :a)
    end

    test "returns default when value missing and default specified" do
      set = KeyValueSet.new!()
      assert :asdf == KeyValueSet.get!(set, :a, :asdf)
    end

    test "raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.get!/3 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.get!(set, :a)
                   end
    end
  end

  describe "Has Key" do
    test "has_key!/2 raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.has_key!/2 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.has_key!(set, :key)
                   end
    end
  end

  describe "First" do
    test "first!/1 requires ordered set" do
      set = KeyValueSet.new!()

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.first!/1 returned {:error, :set_not_ordered}",
                   fn ->
                     KeyValueSet.first!(set)
                   end
    end
  end

  describe "Last" do
    test "last!/1 requires ordered set" do
      set = KeyValueSet.new!()

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.last!/1 returned {:error, :set_not_ordered}",
                   fn ->
                     KeyValueSet.last!(set)
                   end
    end
  end

  describe "Next" do
    test "next!/2 requires ordered set" do
      set = KeyValueSet.new!()

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.next!/2 returned {:error, :set_not_ordered}",
                   fn ->
                     KeyValueSet.next!(set, :a)
                   end
    end
  end

  describe "Previous" do
    test "previous!/2 requires ordered set" do
      set = KeyValueSet.new!()

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.previous!/2 returned {:error, :set_not_ordered}",
                   fn ->
                     KeyValueSet.previous!(set, :a)
                   end
    end
  end

  describe "To List" do
    test "to_list!/1 raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.to_list!/1 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.to_list!(set)
                   end
    end
  end

  describe "Delete" do
    test "delete!/2 raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.delete!/1 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.delete!(set)
                   end
    end

    test "delete!/1 raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.delete!/2 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.delete!(set, :a)
                   end
    end

    test "delete_all!/1 raises on error" do
      set = KeyValueSet.new!()
      KeyValueSet.delete!(set)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.delete_all!/1 returned {:error, :table_not_found}",
                   fn ->
                     KeyValueSet.delete_all!(set)
                   end
    end
  end

  describe "Give Away give_away/3" do
    test "success" do
      recipient_pid = self()

      spawn(fn ->
        bag = KeyValueSet.new!()
        KeyValueSet.give_away!(bag, recipient_pid)
      end)

      assert {:ok, %{kv_set: %KeyValueSet{}, gift: []}} = KeyValueSet.accept()
    end

    test "timeout" do
      assert {:error, :timeout} = KeyValueSet.accept(10)
    end

    test "cannot give to process which already owns table" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.give_away!/3 returned {:error, :recipient_already_owns_table}",
                   fn ->
                     kv_set = KeyValueSet.new!()
                     KeyValueSet.give_away!(kv_set, self())
                   end
    end

    test "cannot give to process which is not alive" do
      assert_raise RuntimeError,
                   "ETS.KeyValueSet.give_away!/3 returned {:error, :recipient_not_alive}",
                   fn ->
                     kv_set = KeyValueSet.new!()
                     KeyValueSet.give_away!(kv_set, TestUtils.dead_pid())
                   end
    end

    test "cannot give a table belonging to another process" do
      sender_pid = self()

      _owner_pid =
        spawn_link(fn ->
          kv_set = KeyValueSet.new!()
          send(sender_pid, kv_set)
          Process.sleep(:infinity)
        end)

      assert_receive kv_set

      recipient_pid = spawn_link(fn -> Process.sleep(:infinity) end)

      assert_raise RuntimeError,
                   "ETS.KeyValueSet.give_away!/3 returned {:error, :sender_not_table_owner}",
                   fn ->
                     KeyValueSet.give_away!(kv_set, recipient_pid)
                   end
    end
  end

  describe "Macro" do
    test "accept/5 success" do
      {:ok, recipient_pid} = start_supervised(ETS.TestServer)

      %KeyValueSet{set: %Set{table: table}} = kv_set = KeyValueSet.new!()

      KeyValueSet.give_away!(kv_set, recipient_pid, :kv_test)

      assert_receive {:thank_you, %KeyValueSet{set: %Set{table: ^table}}}
    end
  end

  def table_name, do: String.to_atom("table#{:rand.uniform(9_999_999)}")

  def table_info(%KeyValueSet{set: %Set{table: table}}), do: table_info(table)

  def table_info(id) do
    id
    |> :ets.info()
    |> Enum.into(%{})
  end
end
