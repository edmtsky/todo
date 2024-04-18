# File.rm_rf("./persist")
# File.mkdir_p("./persist")

ExUnit.start()
ExUnit.configure(exclude: :pending, trace: true, seed: 0)
