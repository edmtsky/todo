defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case
  # import Todo.DatabaseWorker
  @db_directory "./persist"

  setup do
    Todo.Database.cleanup_disk()
    :ok
  end

  test "serialize & desirialize data to disk" do
    {:ok, worker_pid} = Todo.DatabaseWorker.start(@db_directory)

    # serialize to disk
    Todo.DatabaseWorker.store(worker_pid, "name", {:data, :some_value})

    # deserialize from disk
    data = Todo.DatabaseWorker.get(worker_pid, "name")

    assert {:data, :some_value} == data
  end
end
