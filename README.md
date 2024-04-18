# Todo List

A project created for the purpose of learning the Elixir language.
Purpose of the project is to build a distributed HTTP server that
can handle many end users who are simultaneously manipulating many to-do lists.


## Initial check

Run auto unit-test
```sh
mix test
```

Play with project in iex-shell
```sh
iex -S mix
```


## TODO

- [x] develop an infrastructure for handling multiple to-do lists and persisting them to disk.
- [x] datebase pooling and synchronizing


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `todo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:todo, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/todo>.

