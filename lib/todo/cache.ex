defmodule Todo.Cache do
  use Todo.Utils

  # Client API

  def start_link() do
    dputs("Starting to-do cache")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  # return pid of Todo.Server
  @spec server_process(todo_list_name :: String.t()) :: pid
  def server_process(todo_list_name) do
    case start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  # this code will trigger Todo.Server.start_link(todo_list_name)
  defp start_child(todo_list_name) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, todo_list_name}
    )
  end

  # used by Todo.System supervisor to run this Todo.Cache Supervisor as child
  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  @doc """
  terminate Cache and all it childrens(todo-servers)
  since the cache is under the supervisor, it will be automatically restarted
  """
  defp_testable stop() do
    Process.exit(Process.whereis(__MODULE__), :kill)
  end
end
