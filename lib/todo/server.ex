defmodule Todo.Server do
  @moduledoc """
  a process that stores state as a named to-do list
  """
  use GenServer, restart: :temporary
  use Todo.Utils

  @expiry_idle_timeout :timer.seconds(10)

  # Client API

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def add_entry(pid, new_entry) do
    GenServer.cast(pid, {:add_entry, new_entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def update_entry(pid, entry_id, updater_fun) do
    GenServer.cast(pid, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(pid, entry_id) do
    GenServer.cast(pid, {:delete_entry, entry_id})
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  # Implementation (GenServer callbacks)

  @impl GenServer
  def init(name) do
    dputs("Starting to-do server for #{name}.")
    initial_state = {name, nil}
    {:ok, initial_state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    new_state = {name, todo_list}
    {:noreply, new_state, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, entry_id)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:update_entry, entry_id, updater_fun}, {name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, entry_id, updater_fun)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast(invalid_request, state) do
    dbg(invalid_request)
    {:noreply, state, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, todo_list}) do
    entries = Todo.List.entries(todo_list, date)
    {:reply, entries, {name, todo_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call(invalid_request, _from, state) do
    dbg(invalid_request)
    {:replay, :invalid_request, state, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    dputs("Stopping to-do server for #{name}")
    {:stop, :normal, {name, todo_list}}
  end
end
