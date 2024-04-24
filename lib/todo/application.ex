defmodule Todo.Application do
  @moduledoc """
  callback module - implementation of the Application behaviour used as
  entry point to start whole application system
  """
  use Application

  @doc """
  the task of this callback is to start the top-level process of the system

  this is an entry point used in file mix.exs in application/0 function:
  `mod: {Todo.Application, []}`
  """
  @impl Application
  def start(_type, _args) do
    Todo.System.start_link()
  end
end
