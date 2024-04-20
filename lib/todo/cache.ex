defmodule Todo.Cache do
  use GenServer
  use Todo.Utils

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # return pid of Todo.Server
  @spec server_process(todo_list_name :: String.t()) :: pid
  def server_process(todo_list_name) do
    GenServer.call(__MODULE__, {:server_process, todo_list_name})
  end

  # Server callbacks

  @impl GenServer
  def init(_) do
    dputs("Starting to-do cache.")
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start_link(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  @impl GenServer
  def handle_call({:close_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        GenServer.stop(todo_server, :normal)
        new_todo_servers = Map.delete(todo_servers, todo_list_name)
        {:reply, todo_server, new_todo_servers}

      :error ->
        {:reply, :not_found, todo_servers}
    end
  end

  # testing-only Client API

  @doc """
  close the to-do sever process and leaving the to-do list data on the disk
  (remove todo-server-process from memory)
  """
  defp_testable close_process(todo_list_name) do
    cache_pid = Process.whereis(__MODULE__)
    GenServer.call(cache_pid, {:close_process, todo_list_name})
  end

  @doc """
  terminate Cache and all it childrens(todo-servers)
  since the cache is under the supervisor, it will be automatically restarted
  """
  defp_testable stop() do
    Process.exit(Process.whereis(__MODULE__), :kill)
  end
end
