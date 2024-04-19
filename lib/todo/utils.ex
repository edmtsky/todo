defmodule Todo.Utils do
  defmacro __using__(_opts) do
    quote do
      import Todo.Utils
    end
  end

  @doc """
  a way to test private functions in modules in exunit
  https://stackoverflow.com/questions/20949358/
  """
  defmacro defp_testable(head, body \\ nil) do
    if Mix.env() == :test do
      quote do
        def unquote(head) do
          unquote(body[:do])
        end
      end
    else
      quote do
        defp unquote(head) do
          unquote(body[:do])
        end
      end
    end
  end

  @doc """
  debuggins output into console in :dev mode
  The goal is to be silent in tests
  TODO rewrite to macro
  """
  def dputs(msg) do
    if Mix.env() == :dev do
      IO.puts(msg)
    end
  end
end
