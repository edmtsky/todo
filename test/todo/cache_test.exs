defmodule Todo.CacheTest do
  use ExUnit.Case, async: false

  @app_name :todo

  setup do
    Todo.ATestHelper.cleanup_db()
    Application.ensure_started(@app_name)
    :ok
  end

  test "server_process" do
    # {:ok, supervisor} = Todo.System.start_link()
    # Process.sleep(250)
    bob_pid = Todo.Cache.server_process("bob-list")

    assert bob_pid == Todo.Cache.server_process("bob-list")
    assert bob_pid != Todo.Cache.server_process("alice-list")

    # Supervisor.stop(supervisor)
  end

  test "todo-operations" do
    jane_list = Todo.Cache.server_process("jane-list")

    Todo.Server.add_entry(
      jane_list,
      %{date: ~D[2024-04-17], title: "Dentist"}
    )

    entries = Todo.Server.entries(jane_list, ~D[2024-04-17])

    assert [%{date: ~D[2024-04-17], title: "Dentist"}] = entries

    alices_entries =
      Todo.Cache.server_process("alice-list")
      |> Todo.Server.entries(~D[2024-04-17])

    assert [] == alices_entries
  end

  test "persistence" do
    list_name = "john"
    john = Todo.Cache.server_process(list_name)
    Todo.Server.add_entry(john, %{date: ~D[2024-04-20], title: "Shopping"})
    assert 1 == length(Todo.Server.entries(john, ~D[2024-04-20]))

    Process.sleep(200)
    assert Todo.ATestHelper.todo_list_file_exists?(list_name)

    # emulate system restart
    # Supervisor.stop(supervisor)
    # {:ok, supervisor2} = Todo.System.start_link()
    Process.exit(john, :kill)
    Process.sleep(100)

    assert Todo.ATestHelper.todo_list_file_exists?(list_name)

    entries =
      list_name
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(~D[2024-04-20])

    assert [%{date: ~D[2024-04-20], title: "Shopping"}] = entries
  end

  test "restart Todo.Server via Todo.Cache no affects to another proccess" do
    bobs_list_pid = Todo.Cache.server_process("bob-list")
    assert true == Process.alive?(bobs_list_pid)
    assert is_pid(bobs_list_pid)

    bobs_list_pid2 = Todo.Cache.server_process("bob-list")
    assert bobs_list_pid == bobs_list_pid2

    alices_list_pid = Todo.Cache.server_process("alice-list")

    Process.exit(bobs_list_pid, :kill)
    Process.sleep(100)

    bobs_list_pid3 = Todo.Cache.server_process("bob-list")
    assert bobs_list_pid != bobs_list_pid3

    assert false == Process.alive?(bobs_list_pid)
    # not affected
    assert true == Process.alive?(alices_list_pid)
  end

  describe "tooling" do
    test "start_link - auto terminate todoserver on a cache down" do
      cache_pid = Process.whereis(Todo.Cache)
      todo_server_pid = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(cache_pid)
      assert true == Process.alive?(todo_server_pid)

      Process.exit(cache_pid, :kill)
      Process.sleep(100)

      assert false == Process.alive?(cache_pid)
      assert false == Process.alive?(todo_server_pid)

      cache_pid_2 = Process.whereis(Todo.Cache)
      assert true == Process.alive?(cache_pid_2)
      assert cache_pid != cache_pid_2
    end

    test "stop whole cache with Todo.Server processes" do
      cache = Process.whereis(Todo.Cache)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)
      assert is_pid(bobs_list)

      # restart the entire system
      # Supervisor.stop(supervisor)
      # {:ok, supervisor2} = Todo.System.start_link()
      Process.exit(cache, :kill)
      Process.sleep(250)

      assert false == Process.alive?(cache)
      assert true == Process.alive?(Process.whereis(Todo.Cache))
      assert false == Process.alive?(bobs_list)
    end
  end
end
