defmodule Todo.DatabaseWorker do
  use GenServer
  use Todo.Utils

  # Client API

  def start_link(db_directory) do
    GenServer.start_link(__MODULE__, db_directory)
  end

  def store(worker_pid, key, data) do
    GenServer.cast(worker_pid, {:store, key, data})
  end

  def get(worker_pid, key) do
    GenServer.call(worker_pid, {:get, key})
  end

  # Server callbacks

  @impl GenServer
  def init(db_directory) do
    dputs("Starting to-do database-worker.")
    state = {db_directory}
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    key
    |> file_name(state)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(key, state)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(key, {db_directory}) do
    Path.join(db_directory, to_string(key))
  end
end
