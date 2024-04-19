defmodule Todo.Database do
  use GenServer
  use Todo.Utils

  @db_directory "./persist"

  defp file_name(key), do: Path.join(@db_directory, to_string(key))

  # Client API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    worker = select_worker(key)
    Todo.DatabaseWorker.store(worker, key, data)
  end

  def get(key) do
    worker = select_worker(key)
    Todo.DatabaseWorker.get(worker, key)
  end

  # Selecting a worker through a request to the database server process.
  # Information about running workers is stored within the database process state.
  # The purpose of this function is to return the pid of one worker from a pool.
  # The worker is selected based on a specific key - the name of the to-do list.
  # Next, the caller process will talk to the worker directly.
  defp_testable select_worker(key) do
    GenServer.call(__MODULE__, {:select_worker, key})
  end

  # Server callbacks

  @impl GenServer
  def init(_) do
    dputs("Starting to-do database.")
    File.mkdir_p!(@db_directory)
    {:ok, start_workers()}
  end

  defp start_workers() do
    for index <- 1..3, into: %{} do
      {:ok, worker_pid} = Todo.DatabaseWorker.start_link(@db_directory)
      {index - 1, worker_pid}
    end
  end

  @impl GenServer
  def handle_call({:select_worker, key}, _, state) do
    idx = :erlang.phash2(key, 3)
    worker_pid = Map.get(state, idx)
    {:reply, worker_pid, state}
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  @impl GenServer
  def handle_call({:workers}, _, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:stop_db, reason}, state) do
    state
    |> Enum.each(fn {_idx, worker_pid} ->
      GenServer.stop(worker_pid, reason)
    end)

    {:stop, reason, state}
  end

  @doc """
  remove all files from persist directory "ceanup all db-records"
  """
  defp_testable cleanup_disk() do
    {:ok, files} = File.ls(@db_directory)

    files
    |> Enum.each(fn name -> File.rm!(file_name(name)) end)
  end

  @doc """
  for testing - show inner state map of n->worker_pid
  """
  defp_testable workers() do
    GenServer.call(__MODULE__, {:workers})
  end

  @doc """
  stop the entire database and all db-workers
  """
  defp_testable stop_all_db() do
    pid = Process.whereis(__MODULE__)

    if is_pid(pid) do
      GenServer.cast(__MODULE__, {:stop_db, :normal})
      Process.sleep(100)
    end
  end
end
