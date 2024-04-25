defmodule Todo.ATestHelper do
  # Goal: prepare fresh test environment
  # - delete all files from db_dir (Todo.Database)

  # @compile {:nowarn_unused_function, [cleanup_db: 0]}

  # remove all files from persist directory "ceanup all db-records"
  # defp_testable cleanup_disk() do
  def cleanup_db() do
    db_directory = db_directory()
    {:ok, files} = File.ls(db_directory)

    files
    |> Enum.each(fn name ->
      File.rm!(db_file_name(db_directory, name))
    end)
  end

  def todo_list_file_exists?(name) do
    db_directory()
    |> db_file_name(name)
    |> File.exists?()
  end

  defp db_directory() do
    Application.fetch_env!(:todo, :database) |> Keyword.fetch!(:db_directory)
  end

  defp db_file_name(db_directory, list_name) do
    Path.join(db_directory, to_string(list_name))
  end
end
