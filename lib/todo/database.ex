defmodule Todo.Database do
  use GenServer

  @db_directory "./persist"

  defp file_name(key), do: Path.join(@db_directory, to_string(key))

  # Client API

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    worker = select_worker(key)
    Todo.DatabaseWorker.store(worker, key, data)
  end

  def get(key) do
    worker = select_worker(key)
    Todo.DatabaseWorker.get(worker, key)
  end

  def select_worker(key) do
    GenServer.call(__MODULE__, {:select_worker, key})
  end

  # Server callbacks

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_directory)

    state =
      0..2
      |> Enum.reduce(%{}, fn n, acc ->
        {:ok, worker_pid} = Todo.DatabaseWorker.start(@db_directory)
        Map.put(acc, n, worker_pid)
      end)

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    key
    |> file_name()
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  # for testing
  @impl GenServer
  def handle_cast({:stop_db, reason}, state) do
    state
    |> Enum.each(fn {_idx, worker_pid} ->
      GenServer.stop(worker_pid, reason)
    end)

    {:stop, reason, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  @impl GenServer
  def handle_call({:select_worker, key}, _, state) do
    idx = :erlang.phash2(key, 3)
    worker_pid = Map.get(state, idx)
    {:reply, worker_pid, state}
  end

  # for testing
  @impl GenServer
  def handle_call({:workers}, _, state) do
    {:reply, state, state}
  end

  # for testing
  @impl GenServer
  def handle_call({:stop_worker, idx, reason}, _from, state) do
    case Map.fetch(state, idx) do
      {:ok, worker_pid} ->
        GenServer.stop(worker_pid, reason)
        new_state = Map.delete(state, idx)
        {:reply, :ok, new_state}

      :error ->
        {:reply, :not_found, state}
    end
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  @doc """
  remove all files from persist directory "ceanup all db-records"
  """
  def testing_only_cleanup_disk() do
    {:ok, files} = File.ls(@db_directory)

    files
    |> Enum.each(fn name -> File.rm!(file_name(name)) end)
  end

  @doc """
  for testing - show inner state map of n->worker_pid
  """
  def workers() do
    GenServer.call(__MODULE__, {:workers})
  end

  @doc """
  for testing - stop worker by its index in map(0-2)
  """
  def stop_worker(idx, reason \\ :normal) do
    GenServer.cast(__MODULE__, {:stop_worker, idx, reason})
  end

  @doc """
  stop the entire database and all db-workers
  """
  def testing_only_stop_all_db() do
    pid = Process.whereis(__MODULE__)

    if is_pid(pid) do
      GenServer.cast(__MODULE__, {:stop_db, :normal})
      Process.sleep(100)
    end
  end
end
