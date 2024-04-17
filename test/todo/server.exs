defmodule TodoTest do
  use ExUnit.Case
  # doctest Todo

  test "smoke test(initial)" do
    {:ok, todo_server} = Todo.Server.start()

    Todo.Server.add_entry(
      todo_server,
      %{date: ~D[2024-04-17], title: "Programming"}
    )

    assert [%{date: ~D[2024-04-17], id: 1, title: "Programming"}]
      == Todo.Server.entries(todo_server, ~D[2024-04-18])
  end
end
