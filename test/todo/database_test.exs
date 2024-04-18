defmodule Todo.DatabaseTest do
  use ExUnit.Case

  setup do
    Todo.Database.testing_only_cleanup_disk()
    :ok
  end

  describe "init db - create workers" do
    setup do
      Todo.Database.testing_only_stop_all_db()
      :ok
    end

    test "init with workers" do
      Todo.Database.start()
      state = Todo.Database.workers()

      assert 3 == map_size(state)
      assert true == is_pid(Map.get(state, 0))
      assert true == is_pid(Map.get(state, 1))
      assert true == is_pid(Map.get(state, 2))
    end
  end

  describe "select_worker by keyname based on erlang.phash2 [0-2]" do
    setup do
      Todo.Database.testing_only_stop_all_db()
      :ok
    end

    test "select_worker" do
      Todo.Database.start()
      worker_pid1a = Todo.Database.select_worker("a-list")
      worker_pid1b = Todo.Database.select_worker("a-list")
      worker_pid2a = Todo.Database.select_worker("b-list")
      worker_pid2b = Todo.Database.select_worker("b-list")
      worker_pid3a = Todo.Database.select_worker("c-list")
      worker_pid3b = Todo.Database.select_worker("c-list")

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
