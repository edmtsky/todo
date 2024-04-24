defmodule Todo.Database do
  use Todo.Utils

  @pool_size 3
  @db_directory "./persist"

  @moduledoc """
  Poolboy-powered Todo.Database (Supervisor?)
  """

  # Client API

  @doc """
  transaction to work via checkout
  """
  def store(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end

  # used by parent-supervisor instead of the poolboy.start_link
  def child_spec(_) do
    File.mkdir_p!(@db_directory)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      [@db_directory]
    )
  end
end
