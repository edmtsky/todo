defmodule TodoTest do
  use ExUnit.Case

  setup do
    Todo.Database.cleanup_disk()
    Todo.Database.stop_all_db()
    Todo.Database.start()
    :ok
  end

  test "smoke test(initial)" do
    {:ok, todo_server} = Todo.Server.start("mylist")

    Todo.Server.add_entry(
      todo_server,
      %{date: ~D[2024-04-17], title: "Programming"}
    )

    assert true == Process.alive?(todo_server)

    entries = Todo.Server.entries(todo_server, ~D[2024-04-17])
    assert [%{date: ~D[2024-04-17], id: 1, title: "Programming"}] == entries
  end
end
