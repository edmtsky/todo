import Config

#
# Port on which the web server will listen
http_port =
  if config_env() != :test,
    do: System.get_env("TODO_HTTP_PORT", "5454"),
    else: System.get_env("TODO_TEST_HTTP_PORT", "5455")

config :todo, http_port: String.to_integer(http_port)

#
# database directory where to-do lists will be saved
db_directory =
  if config_env() != :test,
    do: System.get_env("TODO_DB_DIR", "./persist"),
    else: System.get_env("TODO_TEST_DB_DIR", "./test_persist")

config :todo, :database, db_directory: db_directory

#
# the count of Todo.DataBaseWorker in the pool
db_pool_size = String.to_integer(System.get_env("TODO_DB_POOL", "3"))
config :todo, :database, db_pool_size: db_pool_size

#
# Using a shorter Todo.Server expiry in local dev.
todo_server_expiry =
  if(config_env() != :dev,
    do: System.get_env("TODO_SERVER_EXPIRY", "60"),
    else: System.get_env("TODO_SERVER_EXPIRY", "10")
  )
  |> String.to_integer()
  |> :timer.seconds()

config :todo, todo_server_expiry: todo_server_expiry

#
# frequency of recording system metrics in secords
metrics_interval =
  if(config_env() != :test,
    do: System.get_env("TODO_METRICS_INTERVAL", "60"),
    else: System.get_env("TODO_TEST_METRICS_INTERVAL", "9999")
  )
  |> String.to_integer()
  |> :timer.seconds()

config :todo, :metrics, interval: metrics_interval
