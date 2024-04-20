defmodule Todo.Database do
  use Todo.Utils

  @pool_size 3
  @db_directory "./persist"

  @moduledoc """
  Supervisor of Todo.DatabaseWorker`s
  """

  defp file_name(key), do: Path.join(@db_directory, to_string(key))

  # Client API

  def start_link() do
    dputs("Starting to-do database server.")
    File.mkdir_p!(@db_directory)

    children_specs = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children_specs, strategy: :one_for_one)
  end

  def store(key, data) do
    key
    |> select_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> select_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  defp worker_spec(worker_id) do
    default_worker_spec = {Todo.DatabaseWorker, {@db_directory, worker_id}}
    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end

  @doc """
  define that this module is Supervisor and to start it need use a start_link/0
  """
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  defp_testable select_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  @doc """
  remove all files from persist directory "ceanup all db-records"
  """
  defp_testable cleanup_disk() do
    {:ok, files} = File.ls(@db_directory)

    files
    |> Enum.each(fn name -> File.rm!(file_name(name)) end)
  end

  # --------------------------------------------------------------------------
  #                            testing helpers

  # to find db_woker_pid by db_worker_id
  defp_testable lookup(worker_id) do
    Registry.lookup(Todo.ProcessRegistry, {Todo.DatabaseWorker, worker_id})
  end

  # show inner state map of ID -> worker_pid
  defp_testable workers() do
    for worker_id <- 1..@pool_size, into: %{} do
      [{worker_pid, _value}] = lookup(worker_id)
      {worker_id, worker_pid}
    end
  end
end
