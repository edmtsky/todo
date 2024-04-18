defmodule Todo.CacheTest do
  use ExUnit.Case

  setup do
    Todo.Database.testing_only_cleanup_disk()
    Todo.Database.testing_only_stop_all_db()
    :ok
  end

  describe "1" do
    test "server_process" do
      {:ok, cache} = Todo.Cache.start()
      bob_pid = Todo.Cache.server_process(cache, "bob-list")

      assert bob_pid == Todo.Cache.server_process(cache, "bob-list")
      assert bob_pid != Todo.Cache.server_process(cache, "alice-list")

      Todo.Cache.testing_only_stop(cache)
    end
  end

  describe "2" do
    test "todo-operations" do
      {:ok, cache} = Todo.Cache.start()

      bobs_list = Todo.Cache.server_process(cache, "bob-list")

      Todo.Server.add_entry(
        bobs_list,
        %{date: ~D[2024-04-17], title: "Dentist"}
      )

      bobs_entries = Todo.Server.entries(bobs_list, ~D[2024-04-17])

      assert [%{id: 1, date: ~D[2024-04-17], title: "Dentist"}] == bobs_entries

      alices_entries =
        Todo.Cache.server_process(cache, "alice-list")
        |> Todo.Server.entries(~D[2024-04-17])

      assert [] == alices_entries

      Todo.Cache.testing_only_stop(cache)
    end
  end

  describe "tooling" do
    # close Todo.Server in runtime
    test "testing_only_close_process" do
      {:ok, cache} = Todo.Cache.start()
      bobs_list = Todo.Cache.server_process(cache, "bob-list")
      assert true == Process.alive?(bobs_list)

      assert bobs_list == Todo.Cache.testing_only_close_process(cache, "bob-list")
      assert false == Process.alive?(bobs_list)
    end

    test "testing_only_stop whole cache with Todo.Server processes" do
      {:ok, cache} = Todo.Cache.start()
      bobs_list = Todo.Cache.server_process(cache, "bob-list")
      assert true == Process.alive?(bobs_list)

      Todo.Cache.testing_only_stop(cache)
      Process.sleep(100)
      assert false == Process.alive?(cache)
      assert false == Process.alive?(bobs_list)
    end
  end
end
