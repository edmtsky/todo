defmodule Todo.Metrics do
  @moduledoc """
  """
  use Task  # inject child_spec/1 what used start_link/1

  @doc """
  main purpose of start_link is to allow OTP compatible process to run under
  supervisor
  """
  def start_link(_arg), do: Task.start_link(&loop/0)

  defp loop() do
    Process.sleep(:timer.seconds(10))
    IO.inspect(collect_metrics())
    loop()
  end

  defp collect_metrics() do
    [
      memory_usage: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count)
    ]
  end
end
