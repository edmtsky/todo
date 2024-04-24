defmodule Todo.WebTest do
  use ExUnit.Case, async: false
  use Plug.Test

  # Test Todo.Web HttpServer

  @app_name :todo

  setup do
    Todo.ATestHelper.cleanup_db()
    Application.ensure_started(@app_name)
    :ok
  end

  test "no entries" do
    resp = get("/entries?list=test_1&date=2024-04-24")
    assert resp.status == 200
    assert resp.resp_body == ""
  end

  test "adding an entry" do
    resp = post("/add_entry?list=test_2&date=2024-04-24&title=Programming")

    assert resp.status == 200
    assert resp.resp_body == "OK"
    resp2 = get("/entries?list=test_2&date=2024-04-24")
    assert resp2.resp_body == "2024-04-24 Programming"
  end

  test "update an entry by entry_id" do
    resp = post("/update_entry?list=test_2&entry_id=1&title=Elixir")

    assert resp.status == 200
    assert resp.resp_body == "OK"
    resp2 = get("/entries?list=test_2&date=2024-04-24")
    assert resp2.resp_body == "2024-04-24 Elixir"
  end

  test "delete an entry by entry_id" do
    # add
    resp = post("/add_entry?list=test_3&date=2024-04-24&title=Bad")

    assert resp.status == 200
    assert resp.resp_body == "OK"
    resp2 = get("/entries?list=test_3&date=2024-04-24")
    assert resp2.resp_body == "2024-04-24 Bad"

    # delete
    resp = get("/delete_entry?list=test_3&entry_id=1")

    assert resp.status == 200
    assert resp.resp_body == "OK"
    resp2 = get("/entries?list=test_3&date=2024-04-24")
    assert resp2.resp_body == ""
  end

  defp get(path) do
    Todo.Web.call(conn(:get, path), Todo.Web.init([]))
  end

  defp post(path) do
    Todo.Web.call(conn(:post, path), Todo.Web.init([]))
  end
end
