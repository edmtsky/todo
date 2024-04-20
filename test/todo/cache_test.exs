defmodule Todo.CacheTest do
  use ExUnit.Case, async: false

  setup do
    Todo.Database.cleanup_disk()
    :ok
  end

  test "server_process" do
    Todo.System.start_link()
    Process.sleep(250)
    bob_pid = Todo.Cache.server_process("bob-list")

    assert bob_pid == Todo.Cache.server_process("bob-list")
    assert bob_pid != Todo.Cache.server_process("alice-list")

    Todo.Cache.stop()
  end

  test "todo-operations" do
    Todo.System.start_link()
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

    Todo.Cache.stop()
  end

  test "persistence" do
    {:ok, supervisor} = Todo.System.start_link()
    Process.sleep(250)

    john = Todo.Cache.server_process("john")
    Todo.Server.add_entry(john, %{date: ~D[2024-04-20], title: "Shopping"})
    assert 1 == length(Todo.Server.entries(john, ~D[2024-04-20]))

    # emulate system restart
    Supervisor.stop(supervisor)
    Todo.System.start_link()

    entries =
      "john"
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(~D[2024-04-20])

    assert [%{date: ~D[2024-04-20], title: "Shopping"}] = entries
  end

  describe "tooling" do
    # close Todo.Server in runtime
    test "close_process(Todo.Server)" do
      Todo.System.start_link()
      Process.sleep(250)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)

      assert bobs_list == Todo.Cache.close_process("bob-list")
      assert false == Process.alive?(bobs_list)
    end

    test "stop whole cache with Todo.Server processes and Database" do
      {:ok, supervisor} = Todo.System.start_link()
      Process.sleep(250)
      cache = Process.whereis(Todo.Cache)
      bobs_list = Todo.Cache.server_process("bob-list")
      assert true == Process.alive?(bobs_list)

      # restart the entire system
      Supervisor.stop(supervisor)
      Todo.System.start_link()
      Process.sleep(100)

      assert false == Process.alive?(cache)
      assert true == Process.alive?(Process.whereis(Todo.Cache))
      assert false == Process.alive?(bobs_list)
    end
  end
end
