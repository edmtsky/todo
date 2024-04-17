defmodule Todo.CacheTest do
  use ExUnit.Case

  test "server_process" do
    {:ok, cache} = Todo.Cache.start()
    bob_pid = Todo.Cache.server_process(cache, "bob-list")

    assert bob_pid == Todo.Cache.server_process(cache, "bob-list")
    assert bob_pid != Todo.Cache.server_process(cache, "alice-list")
  end

  test "todo-operations" do
    {:ok, cache} = Todo.Cache.start()

    bobs_list = Todo.Cache.server_process(cache, "Bob's list")

    Todo.Server.add_entry(
      bobs_list,
      %{date: ~D[2024-04-17], title: "Dentist"}
    )
    bobs_entries = Todo.Server.entries(bobs_list, ~D[2024-04-17])

    assert [%{id: 1, date: ~D[2024-04-17], title: "Dentist"}] == bobs_entries

    alices_entries = Todo.Cache.server_process(cache, "Alice's list") |>
      Todo.Server.entries(~D[2024-04-17])

    assert [] == alices_entries
  end
end
