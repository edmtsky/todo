defmodule Todo.DatabaseTest do
  use ExUnit.Case, async: false
  alias Todo.Database, as: DB

  @app_name :todo
  @pool_size 3

  setup do
    DB.cleanup_disk()
    Application.ensure_started(@app_name)
    # Todo.ProcessRegistry.start_link(); Process.sleep(200)
    # Todo.Database.start_link(); Process.sleep(200)
    :ok
  end

  # test helpers

  # to find db_woker_pid by db_worker_id
  defp lookup(worker_id) do
    Registry.lookup(Todo.ProcessRegistry, {Todo.DatabaseWorker, worker_id})
  end

  # to show inner state map of ID -> worker_pid
  defp workers() do
    for worker_id <- 1..@pool_size, into: %{} do
      [{worker_pid, _value}] = lookup(worker_id)
      {worker_id, worker_pid}
    end
  end

  # --


  test "tooling workers to check correctness of the db startup" do
    workers = Todo.Database.workers()
    assert 3 == map_size(workers)
    assert true == is_pid(Map.get(workers, 1))
    assert true == is_pid(Map.get(workers, 2))
    assert true == is_pid(Map.get(workers, 3))
  end

  test "select_worker" do
    worker_id1a = DB.select_worker("a-list")
    worker_id1b = DB.select_worker("a-list")
    worker_id2a = DB.select_worker("b-list")
    worker_id2b = DB.select_worker("b-list")
    worker_id3a = DB.select_worker("c-list")
    worker_id3b = DB.select_worker("c-list")

    assert 2 == worker_id1a
    assert 2 == worker_id1b
    assert worker_id1a == worker_id1b

    assert 3 == worker_id2a
    assert 3 == worker_id2b
    assert worker_id2a == worker_id2b

    assert 1 == worker_id3a
    assert 1 == worker_id3b
    assert worker_id3a == worker_id3b

    assert worker_id1a != worker_id2a
    assert worker_id3a != worker_id1a
    assert worker_id3a != worker_id2a
  end

  test "tooling lookup" do
    worker_id = 1
    [{worker_pid, nil}] = Todo.Database.lookup(worker_id)
    assert is_pid(worker_pid)
  end
end
