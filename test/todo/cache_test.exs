defmodule Todo.CacheTest do
  use ExUnit.Case

  setup do
    Todo.Database.cleanup_disk()
    Todo.Database.stop_all_db()
    :ok
  end

  describe "1" do
    test "server_process" do
      {:ok, _cache} = Todo.Cache.start_link(nil)
      bob_pid = Todo.Cache.server_process("bob-list")

      assert bob_pid == Todo.Cache.server_process("bob-list")
      assert bob_pid != Todo.Cache.server_process("alice-list")

      Todo.Cache.stop()
    end
  end

  describe "2" do
    test "todo-operations" do
      {:ok, _cache} = Todo.Cache.start_link(nil)

      bobs_list = Todo.Cache.server_process("bob-list")

      Todo.Server.add_entry(
        bobs_list,
        %{date: ~D[2024-04-17], title: "Dentist"}
      )

      bobs_entries = Todo.Server.entries(bobs_list, ~D[2024-04-17])

      assert [%{id: 1, date: ~D[2024-04-17], title: "Dentist"}] == bobs_entries

      alices_entries =
        Todo.Cache.server_process("alice-list")
        |> Todo.Server.entries(~D[2024-04-17])

      assert [] == alices_entries

      Todo.Cache.stop()
    end
  end

  describe "tooling" do
    # close Todo.Server in runtime
    test "close_process(Todo.Server)" do
      {:ok, _cache} = Todo.Cache.start_link(nil)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)

      assert bobs_list == Todo.Cache.close_process("bob-list")
      assert false == Process.alive?(bobs_list)
    end

    test "stop whole cache with Todo.Server processes and Database" do
      {:ok, cache} = Todo.Cache.start_link(nil)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)

      Todo.Cache.stop()
      Process.sleep(100)
      assert false == Process.alive?(cache)
      assert false == Process.alive?(bobs_list)
    end
  end
end
