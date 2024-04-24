defmodule Todo.ATestHelper do
  # Goal: prepare fresh test environment
  # - delete all files from db_dir (Todo.Database)

  @db_directory "./persist"

  # @compile {:nowarn_unused_function, [cleanup_db: 0]}

  # remove all files from persist directory "ceanup all db-records"
  # defp_testable cleanup_disk() do
  def cleanup_db() do
    {:ok, files} = File.ls(@db_directory)

    files
    |> Enum.each(fn name ->
      File.rm!(Path.join(@db_directory, to_string(name)))
    end)
  end
end
