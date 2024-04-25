defmodule Todo.Web do
  @moduledoc """
  Http-interface (web-server)
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def child_spec(_arg) do
    Plug.Cowboy.child_spec(
      scheme: :http,
      options: [port: Application.fetch_env!(:todo, :http_port)],
      plug: __MODULE__
    )
  end

  # curl -d '' 'http://localhost:5454/add_entry?list=bob&date=2024-04-24&title=Elixir'
  post "/add_entry" do
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    title = Map.fetch!(conn.params, "title")
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.add_entry(%{title: title, date: date})

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "OK")
  end

  # curl -d '' 'http://localhost:5454/update_entry?list=bob&entry_id=1&title=Elixir'
  post "/update_entry" do
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    {entry_id, _} = Integer.parse(Map.fetch!(conn.params, "entry_id"))
    updated_title = Map.fetch!(conn.params, "title")

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.update_entry(entry_id, &Map.put(&1, :title, updated_title))

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "OK")
  end

  # curl 'http://localhost:5454/entries?list=bob&date=2024-04-24'
  get "/entries" do
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    entries =
      list_name
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(date)

    formatted_entries =
      entries
      |> Enum.map(&"#{&1.date} #{&1.title}")
      |> Enum.join("\n")

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, formatted_entries)
  end

  # curl -d '' 'http://localhost:5454/update_entry?list=bob&entry_id=1
  get "/delete_entry" do
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    {entry_id, _} = Integer.parse(Map.fetch!(conn.params, "entry_id"))

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.delete_entry(entry_id)

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "OK")
  end

  match _ do
    Plug.Conn.send_resp(conn, 404, "not found")
  end
end
