defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case, async: false

  @app_name :todo
  @db_directory "./persist"

  setup do
    Todo.Database.cleanup_disk()
    Application.ensure_started(@app_name)
    # Todo.ProcessRegistry.start_link()  was necessary before add OTP-aplication
    :ok
  end

  test "serialize & desirialize data to disk" do
    worker_id = 1
    # {:ok, pid} = Todo.DatabaseWorker.start_link({@db_directory, worker_id})

    {:error, {:already_started, pid}} =
      Todo.DatabaseWorker.start_link({@db_directory, worker_id})

    # serialize to disk
    Todo.DatabaseWorker.store(worker_id, "name", {:data, :some_value})

    # deserialize from disk
    data = Todo.DatabaseWorker.get(worker_id, "name")

    assert {:data, :some_value} == data
    assert is_pid(pid)
  end
end
