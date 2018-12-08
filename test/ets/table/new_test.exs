defmodule EtsTableNewTest do
  # use ExUnit.Case
  # alias Ets.Table.New
  # doctest New

  # describe "Named Tables Start" do
  #   setup do
  #     {:ok, %{name: String.to_atom("table#{:rand.uniform(9_999_999)}")}}
  #   end

  #   test "Bag", %{name: name} do
  #     assert name = New.bag!(name)
  #     assert %{name: ^name, named_table: true, type: :bag} = table_info(name)
  #   end

  #   test "Duplicate Bag", %{name: name} do
  #     assert ^name = New.duplicate_bag!(name)
  #     assert %{name: ^name, named_table: true, type: :duplicate_bag} = table_info(name)
  #   end

  #   test "Ordered Set", %{name: name} do
  #     assert ^name = New.ordered_set!(name)
  #     assert %{name: ^name, named_table: true, type: :ordered_set} = table_info(name)
  #   end

  #   test "Set", %{name: name} do
  #     assert ^name = New.set!(name)
  #     assert %{name: ^name, named_table: true, type: :set} = table_info(name)
  #   end
  # end

  # describe "Unnamed Tables Start" do
  #   test "Bag" do
  #     ref = New.bag!()
  #     assert is_reference(ref)
  #     assert %{named_table: false, type: :bag} = table_info(ref)
  #   end

  #   test "Duplicate Bag" do
  #     ref = New.duplicate_bag!()
  #     assert is_reference(ref)
  #     assert %{named_table: false, type: :duplicate_bag} = table_info(ref)
  #   end

  #   test "Ordered Set" do
  #     ref = New.ordered_set!()
  #     assert is_reference(ref)
  #     assert %{named_table: false, type: :ordered_set} = table_info(ref)
  #   end

  #   test "Set" do
  #     ref = New.set!()
  #     assert is_reference(ref)
  #     assert %{named_table: false, type: :set} = table_info(ref)
  #   end
  # end

  # describe "Options set correctly" do
  #   test "Access" do
  #     assert %{protection: :private} = table_info(New.set!(protection: :private))

  #     assert %{protection: :public} = table_info(New.duplicate_bag!(protection: :public))

  #     assert %{protection: :protected} = table_info(New.ordered_set!(protection: :protected))
  #   end

  #   test "Heir" do
  #     slf = self()
  #     assert %{heir: :none} = table_info(New.bag!(heir: :none))
  #     assert %{heir: ^slf} = table_info(New.set!(heir: {slf, :some_data}))
  #   end

  #   test "Keypos" do
  #     assert %{keypos: 5} = table_info(New.set!(keypos: 5))
  #     assert %{keypos: 55} = table_info(New.set!(keypos: 55))
  #   end

  #   test "Write Concurrency" do
  #     assert %{write_concurrency: true} = table_info(New.set!(write_concurrency: true))
  #     assert %{write_concurrency: false} = table_info(New.set!(write_concurrency: false))

  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:write_concurrency, :not_a_boolean}}}",
  #                  fn -> New.set!(write_concurrency: :not_a_boolean) end
  #   end

  #   test "Read Concurrency" do
  #     assert %{read_concurrency: true} = table_info(New.set!(read_concurrency: true))
  #     assert %{read_concurrency: false} = table_info(New.set!(read_concurrency: false))

  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:read_concurrency, :not_a_boolean}}}",
  #                  fn -> New.set!(read_concurrency: :not_a_boolean) end
  #   end

  #   test "Compressed" do
  #     assert %{compressed: true} = table_info(New.set!(compressed: true))
  #     assert %{compressed: false} = table_info(New.set!(compressed: false))

  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:compressed, :not_a_boolean}}}",
  #                  fn -> New.set!(compressed: :not_a_boolean) end
  #   end
  # end

  # describe "Rejects bad options" do
  #   test "Access" do
  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:protection, :nobody}}}",
  #                  fn ->
  #                    New.set!(protection: :nobody)
  #                  end
  #   end

  #   test "Heir" do
  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:heir, :nobody}}}",
  #                  fn ->
  #                    New.set!(heir: :nobody)
  #                  end

  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:heir, {:not_a_pid, :data}}}}",
  #                  fn -> New.set!(heir: {:not_a_pid, :data}) end
  #   end

  #   test "Keypos" do
  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:keypos, -1}}}",
  #                  fn ->
  #                    New.set!(keypos: -1)
  #                  end

  #     assert_raise RuntimeError,
  #                  "Ets.Table.New.set!/1 returned {:error, {:invalid_option, {:keypos, :not_a_number}}}",
  #                  fn ->
  #                    New.set!(keypos: :not_a_number)
  #                  end
  #   end
  # end

  # def table_info(id) do
  #   id
  #   |> :ets.info()
  #   |> Enum.into(%{})
  # end
end
