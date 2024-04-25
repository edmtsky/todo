defmodule Todo.Database do
  use Todo.Utils

  @moduledoc """
  Poolboy-powered Todo.Database (Supervisor?)
  """

  # Client API

  def store(key, data) do
    # transaction to work via checkout
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
    db_settings = Application.fetch_env!(:todo, :database)
    db_directory = Keyword.fetch!(db_settings, :db_directory)
    db_pool_size = Keyword.fetch!(db_settings, :db_pool_size)

    File.mkdir_p!(db_directory)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: db_pool_size
      ],
      [db_directory]
    )
  end
end
