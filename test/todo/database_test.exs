defmodule Todo.DatabaseTest do
  use ExUnit.Case, async: false
  alias Todo.Database, as: DB

  @app_name :todo

  setup do
    Todo.ATestHelper.cleanup_db()
    Application.ensure_started(@app_name)
    :ok
  end

  test "Client API store ang get" do
    assert :ok = DB.store("key_name", {:data, :some_value})

    data = DB.get("key_name")

    assert {:data, :some_value} == data
  end
end
