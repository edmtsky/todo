defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case, async: false

  @app_name :todo

  setup do
    Todo.ATestHelper.cleanup_db()
    Application.ensure_started(@app_name)
    :ok
  end

  test "serialize & desirialize data to disk(store and get)" do
    {:ok, worker_pid} = Todo.DatabaseWorker.start_link(db_directory())

    # serialize to disk
    Todo.DatabaseWorker.store(worker_pid, "name", {:data, :some_value})

    # deserialize from disk
    data = Todo.DatabaseWorker.get(worker_pid, "name")

    assert {:data, :some_value} == data
    assert is_pid(worker_pid)
  end

  defp db_directory() do
    Application.fetch_env!(:todo, :database) |> Keyword.fetch!(:db_directory)
  end
end
