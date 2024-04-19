defmodule Todo.DatabaseTest do
  use ExUnit.Case
  alias Todo.Database, as: DB

  setup do
    DB.cleanup_disk()
    :ok
  end

  describe "init db - create workers" do
    setup do
      DB.stop_all_db()
      :ok
    end

    test "init with workers" do
      Todo.Database.start_link()
      state = Todo.Database.workers()

      assert 3 == map_size(state)
      assert true == is_pid(Map.get(state, 0))
      assert true == is_pid(Map.get(state, 1))
      assert true == is_pid(Map.get(state, 2))
    end
  end

  describe "select_worker by keyname based on erlang.phash2 [0-2]" do
    setup do
      DB.stop_all_db()
      :ok
    end

    test "select_worker" do
      Todo.Database.start_link()
      worker_pid1a = DB.select_worker("a-list")
      worker_pid1b = DB.select_worker("a-list")
      worker_pid2a = DB.select_worker("b-list")
      worker_pid2b = DB.select_worker("b-list")
      worker_pid3a = DB.select_worker("c-list")
      worker_pid3b = DB.select_worker("c-list")

      assert true == is_pid(worker_pid1a)
      assert true == is_pid(worker_pid1b)
      assert worker_pid1a == worker_pid1b

      assert true == is_pid(worker_pid2a)
      assert true == is_pid(worker_pid2b)
      assert worker_pid2a == worker_pid2b

      assert true == is_pid(worker_pid3a)
      assert true == is_pid(worker_pid3b)
      assert worker_pid3a == worker_pid3b

      assert worker_pid1a != worker_pid2a
      assert worker_pid3a != worker_pid1a
      assert worker_pid3a != worker_pid2a
    end
  end
end
