defmodule Todo.CacheTest do
  use ExUnit.Case, async: false

  setup do
    Todo.Database.cleanup_disk()
    :ok
  end

  test "server_process" do
    {:ok, supervisor} = Todo.System.start_link()
    Process.sleep(250)
    bob_pid = Todo.Cache.server_process("bob-list")

    assert bob_pid == Todo.Cache.server_process("bob-list")
    assert bob_pid != Todo.Cache.server_process("alice-list")

    Supervisor.stop(supervisor)
  end

  test "todo-operations" do
    {:ok, supervisor} = Todo.System.start_link()
    Process.sleep(250)

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

    Supervisor.stop(supervisor)
  end

  test "persistence" do
    {:ok, supervisor} = Todo.System.start_link()
    Process.sleep(250)

    john = Todo.Cache.server_process("john")
    Todo.Server.add_entry(john, %{date: ~D[2024-04-20], title: "Shopping"})
    assert 1 == length(Todo.Server.entries(john, ~D[2024-04-20]))

    assert File.exists?("persist/john")

    # emulate system restart
    Supervisor.stop(supervisor)
    {:ok, supervisor2} = Todo.System.start_link()
    Process.sleep(250)

    assert File.exists?("persist/john")

    entries =
      "john"
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(~D[2024-04-20])

    assert [%{date: ~D[2024-04-20], title: "Shopping"}] = entries

    Supervisor.stop(supervisor2)
  end

  describe "tooling" do
    test "start_link - auto terminate todoserver on a cache down" do
      {:ok, supervisor} = Todo.System.start_link()
      Process.sleep(250)

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

      Supervisor.stop(supervisor)
    end

    # close Todo.Server in runtime
    test "close_process(Todo.Server)" do
      {:ok, supervisor} = Todo.System.start_link()
      Process.sleep(250)

      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)

      assert bobs_list == Todo.Cache.close_process("bob-list")
      assert false == Process.alive?(bobs_list)

      Supervisor.stop(supervisor)
    end

    test "stop whole cache with Todo.Server processes" do
      {:ok, supervisor} = Todo.System.start_link()
      Process.sleep(250)

      cache = Process.whereis(Todo.Cache)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)
      assert is_pid(bobs_list)

      # restart the entire system
      Supervisor.stop(supervisor)
      {:ok, supervisor2} = Todo.System.start_link()
      Process.sleep(250)

      assert false == Process.alive?(cache)
      assert true == Process.alive?(Process.whereis(Todo.Cache))
      assert false == Process.alive?(bobs_list)

      Supervisor.stop(supervisor2)
    end
  end
end
