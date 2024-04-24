defmodule TodoTest do
  use ExUnit.Case, async: false

  @app_name :todo

  setup do
    Todo.ATestHelper.cleanup_db()
    Application.ensure_started(@app_name)
    :ok
  end

  test "smoke test(initial)" do
    # Todo.ProcessRegistry.start_link(); Process.sleep(250)
    # Todo.Database.start_link(); Process.sleep(250)

    {:ok, todo_server} = Todo.Server.start_link("mylist")

    Todo.Server.add_entry(
      todo_server,
      %{date: ~D[2024-04-17], title: "Programming"}
    )

    assert true == Process.alive?(todo_server)

    entries = Todo.Server.entries(todo_server, ~D[2024-04-17])
    assert [%{date: ~D[2024-04-17], id: 1, title: "Programming"}] == entries
  end
end
