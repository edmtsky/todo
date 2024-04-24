# File.rm_rf("./persist")
# File.mkdir_p("./persist")

Code.require_file("#{__DIR__}/todo/a_test_helper.exs")

ExUnit.start()
ExUnit.configure(exclude: :pending, trace: true, seed: 0)
