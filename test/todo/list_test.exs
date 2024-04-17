defmodule Todo.ListTest do
  use ExUnit.Case, async: true

  test "empty list" do
    assert 0 == Todo.List.size(Todo.List.new())
  end

  test "entries" do
    todo_list =
      Todo.List.new([
        %{date: ~D[2024-04-17], title: "Dentist"},
        %{date: ~D[2024-04-16], title: "Shopping"},
        %{date: ~D[2024-04-17], title: "Movies"}
      ])

    assert 3 == Todo.List.size(todo_list)
    assert 2 == todo_list |> Todo.List.entries(~D[2024-04-17]) |> length()
    assert 1 == todo_list |> Todo.List.entries(~D[2024-04-16]) |> length()
    assert 0 == todo_list |> Todo.List.entries(~D[2024-04-13]) |> length()

    titles =
      todo_list
      |> Todo.List.entries(~D[2024-04-17])
      |> Enum.map(& &1.title)

    assert ["Dentist", "Movies"] == titles
  end

  test "add_entry" do
    todo_list =
      Todo.List.new()
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Dentist"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-20], title: "Shopping"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Movies"})

    assert 3 == Todo.List.size(todo_list)
    assert 2 == todo_list |> Todo.List.entries(~D[2024-03-19]) |> length()
    assert 1 == todo_list |> Todo.List.entries(~D[2024-03-20]) |> length()
    assert 0 == todo_list |> Todo.List.entries(~D[2024-03-21]) |> length()

    titles =
      todo_list
      |> Todo.List.entries(~D[2024-03-19])
      |> Enum.map(& &1.title)

    assert ["Dentist", "Movies"] = titles
  end

  test "update_entry" do
    todo_list =
      Todo.List.new()
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Dentist"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-20], title: "Shopping"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Movies"})
      |> Todo.List.update_entry(2, &Map.put(&1, :title, "Updated shopping"))

    assert 3 == Todo.List.size(todo_list)

    assert [%{title: "Updated shopping"}] =
             Todo.List.entries(todo_list, ~D[2024-03-20])
  end

  test "delete_entry" do
    todo_list =
      Todo.List.new()
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Dentist"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-20], title: "Shopping"})
      |> Todo.List.add_entry(%{date: ~D[2024-03-19], title: "Movies"})
      |> Todo.List.delete_entry(2)

    assert 2 == Todo.List.size(todo_list)
    assert [] == Todo.List.entries(todo_list, ~D[2024-03-20])
  end
end
