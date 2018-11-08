defmodule EtsNewTest do
  use ExUnit.Case
  doctest Ets.New

  describe "Named Tables Start" do
    setup do
      {:ok, %{name: String.to_atom("table#{:rand.uniform(9_999_999)}")}}
    end

    test "Bag", %{name: name} do
      assert ^name = Ets.New.bag(name)
      assert %{name: ^name, named_table: true, type: :bag} = table_info(name)
    end

    test "Duplicate Bag", %{name: name} do
      assert ^name = Ets.New.duplicate_bag(name)
      assert %{name: ^name, named_table: true, type: :duplicate_bag} = table_info(name)
    end

    test "Ordered Set", %{name: name} do
      assert ^name = Ets.New.ordered_set(name)
      assert %{name: ^name, named_table: true, type: :ordered_set} = table_info(name)
    end

    test "Set", %{name: name} do
      assert ^name = Ets.New.set(name)
      assert %{name: ^name, named_table: true, type: :set} = table_info(name)
    end
  end

  describe "Unnamed Tables Start" do
    test "Bag" do
      ref = Ets.New.bag()
      assert is_reference(ref)
      assert %{named_table: false, type: :bag} = table_info(ref)
    end

    test "Duplicate Bag" do
      ref = Ets.New.duplicate_bag()
      assert is_reference(ref)
      assert %{named_table: false, type: :duplicate_bag} = table_info(ref)
    end

    test "Ordered Set" do
      ref = Ets.New.ordered_set()
      assert is_reference(ref)
      assert %{named_table: false, type: :ordered_set} = table_info(ref)
    end

    test "Set" do
      ref = Ets.New.set()
      assert is_reference(ref)
      assert %{named_table: false, type: :set} = table_info(ref)
    end
  end

  describe "Options set correctly" do
    test "Access" do
      assert %{protection: :private} = table_info(Ets.New.set(access: :private))
      assert %{protection: :public} = table_info(Ets.New.set(access: :public))
      assert %{protection: :protected} = table_info(Ets.New.set(access: :protected))
    end

    test "Heir" do
      slf = self()
      assert %{heir: :none} = table_info(Ets.New.set(heir: :none))
      assert %{heir: ^slf} = table_info(Ets.New.set(heir: {slf, :some_data}))
    end

    test "Keypos" do
      assert %{keypos: 5} = table_info(Ets.New.set(keypos: 5))
      assert %{keypos: 55} = table_info(Ets.New.set(keypos: 55))
    end
  end

  describe "Rejects bad options" do
    test "Access" do
      assert_raise ArgumentError, "Invalid opt passed to Ets.New: {:access, :nobody}", fn ->
        Ets.New.set(access: :nobody)
      end
    end

    test "Heir" do
      assert_raise ArgumentError, "Invalid opt passed to Ets.New: {:heir, :nobody}", fn ->
        Ets.New.set(heir: :nobody)
      end

      assert_raise ArgumentError,
                   "Invalid opt passed to Ets.New: {:heir, {:not_a_pid, :data}}",
                   fn -> Ets.New.set(heir: {:not_a_pid, :data}) end
    end

    test "Keypos" do
      assert_raise ArgumentError, "Invalid opt passed to Ets.New: {:keypos, -1}", fn ->
        Ets.New.set(keypos: -1)
      end

      assert_raise ArgumentError, "Invalid opt passed to Ets.New: {:keypos, :not_a_number}", fn ->
        Ets.New.set(keypos: :not_a_number)
      end
    end
  end

  def table_info(id) do
    id
    |> :ets.info()
    |> Enum.into(%{})
  end
end
