defmodule Todo.SystemTest do
  use ExUnit.Case, async: false

  @app_name :todo

  describe "Todo.system" do
    test "link all processes in one tree" do
      Application.stop(@app_name)

      Todo.System.start_link()
      Process.sleep(100)
      bobs_list1 = Todo.Cache.server_process("Bob's list")
      processes_cnt = length(Process.list())

      Process.exit(Process.whereis(Todo.Cache), :kill)
      Process.sleep(200)
      bobs_list2 = Todo.Cache.server_process("Bob's list")

      assert processes_cnt == length(Process.list())
      assert is_pid(bobs_list1)
      assert is_pid(bobs_list2)
      assert bobs_list1 != bobs_list2
    end
  end
end
