# 17-04-2024 @author Edmtsky
defmodule Todo.DatabaseTest do
  use ExUnit.Case

  setup do
    Todo.Database.testing_only_cleanup()
    :ok
  end

  test "serialize& desirialize data to the disk" do
    {:ok, cache_1} = Todo.Cache.start()

    mylist = Todo.Cache.server_process(cache_1, "mylist")

    Todo.Server.add_entry(
      mylist,
      %{date: ~D[2024-04-17], title: "Programming"}
    )

    entries = Todo.Server.entries(mylist, ~D[2024-04-17])
    assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries

    # emulate system restart

    Todo.Cache.testing_only_stop(cache_1)
    Process.sleep(100)
    assert false == Process.alive?(mylist)
    assert false == Process.alive?(cache_1)

    {:ok, cache_2} = Todo.Cache.start()
    mylist_2 = Todo.Cache.server_process(cache_2, "mylist")
    entries_2 = Todo.Server.entries(mylist_2, ~D[2024-04-17])
    assert [%{id: 1, date: ~D[2024-04-17], title: "Programming"}] == entries_2
  end
end
