defmodule Todo.IntegrationTest do
  use ExUnit.Case, async: false

  setup do
    Todo.Database.cleanup_disk()
    :ok
  end

  describe "Todo.System, Todo.ProcessRegistry, Todo.Cache, Todo.Database" do
    test "serialize & deserialize data to the disk" do
      proc_cnt_1 = length(Process.list())
      {:ok, supervisor} = Todo.System.start_link()
      Process.sleep(250)
      cache_1 = Process.whereis(Todo.Cache)

      mylist = Todo.Cache.server_process("mylist")

      Todo.Server.add_entry(
        mylist,
        %{date: ~D[2024-04-17], title: "Programming"}
      )

      entries = Todo.Server.entries(mylist, ~D[2024-04-17])
      assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries
      assert File.exists?("persist/mylist")

      # emulate a system shutdown, keep data on the disk

      assert true == Process.alive?(mylist)
      assert true == Process.alive?(cache_1)
      # assert true == is_pid(Process.whereis(Todo.Database)) work with GenServer
      # Todo how to check is supervisor is alive?
      assert [{_pid, nil}] = Todo.Database.lookup(1)

      Supervisor.stop(supervisor)
      Process.sleep(250)

      # ensure off
      assert false == Process.alive?(mylist)
      assert false == Process.alive?(cache_1)
      # assert nil == Process.whereis(Todo.Database)
      proc_cnt_2 = length(Process.list())
      assert proc_cnt_1 == proc_cnt_2

      # restart the system
      {:ok, _supervisor} = Todo.System.start_link()
      Process.sleep(250)
      cache_2 = Process.whereis(Todo.Cache)
      assert true == is_pid(cache_2)
      assert cache_2 != cache_1
      # assert true == is_pid(Process.whereis(Todo.Database)) ??

      # TODO fix issue with parallel test runs and deleting data from the db
      assert File.exists?("persist/mylist")
      mylist_2 = Todo.Cache.server_process("mylist")
      entries_2 = Todo.Server.entries(mylist_2, ~D[2024-04-17])

      assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries_2
    end
  end
end
