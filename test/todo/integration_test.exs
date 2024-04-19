defmodule Todo.IntegrationTest do
  use ExUnit.Case

  setup do
    Todo.Database.cleanup_disk()
    :ok
  end

  describe "persisting data(Todo.Cache, Todo.Database" do
    test "serialize & deserialize data to the disk" do
      {:ok, cache_1} = Todo.Cache.start_link(nil)

      mylist = Todo.Cache.server_process("mylist")

      Todo.Server.add_entry(
        mylist,
        %{date: ~D[2024-04-17], title: "Programming"}
      )

      entries = Todo.Server.entries(mylist, ~D[2024-04-17])
      assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries

      # emulate a system shutdown, keep data on the disk

      assert true == Process.alive?(mylist)
      assert true == Process.alive?(cache_1)
      assert true == is_pid(Process.whereis(Todo.Database))

      Todo.Cache.stop()
      Todo.Database.stop_all_db()
      Process.sleep(100)

      # ensure off
      assert false == Process.alive?(mylist)
      assert false == Process.alive?(cache_1)
      assert nil == Process.whereis(Todo.Database)

      # restart the system
      {:ok, cache_2} = Todo.Cache.start_link(nil)
      assert true == is_pid(Process.whereis(Todo.Database))

      mylist_2 = Todo.Cache.server_process("mylist")
      entries_2 = Todo.Server.entries(mylist_2, ~D[2024-04-17])

      assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries_2
      assert cache_2 != cache_1
    end
  end
end
