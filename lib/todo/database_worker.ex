defmodule Todo.DatabaseWorker do
  use GenServer
  use Todo.Utils

  # Client API

  def start_link({db_directory, worker_id}) do
    GenServer.start_link(__MODULE__, db_directory, name: via_tuple(worker_id))
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
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
