defmodule Todo.Cache do
  use GenServer

  # Client API
  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:server_process, todo_list_name})
  end

  # Server callbacks

  @impl GenServer
  def init(_) do
    Todo.Database.start()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start(todo_list_name)

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

  @impl GenServer
  def handle_cast({:close_all_process}, todo_servers) do
    todo_servers
    |> Enum.each(fn {_todo_list_name, todo_server_pid} ->
      GenServer.stop(todo_server_pid, :normal)
    end)

    {:stop, :normal, %{}}
  end

  # testing-only Client API

  @doc """
  close the to-do sever process and leaving the to-do list data on the disk
  (remove todo-server-process from memory)
  """
  def testing_only_close_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:close_process, todo_list_name})
  end

  def testing_only_stop(cache_pid, reason \\ :normal) do
    GenServer.cast(cache_pid, {:close_all_process})
    GenServer.stop(Todo.Database, reason)
  end
end
