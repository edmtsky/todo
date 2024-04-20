defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case, async: false
  # import Todo.DatabaseWorker
  @db_directory "./persist"

  setup do
    Todo.Database.cleanup_disk()
    Todo.ProcessRegistry.start_link()
    :ok
  end

  test "serialize & desirialize data to disk" do
    worker_id = 1
    {:ok, pid} = Todo.DatabaseWorker.start_link({@db_directory, worker_id})

    # serialize to disk
    Todo.DatabaseWorker.store(worker_id, "name", {:data, :some_value})

    # deserialize from disk
    data = Todo.DatabaseWorker.get(worker_id, "name")

    assert {:data, :some_value} == data
    assert is_pid(pid)
  end
end
