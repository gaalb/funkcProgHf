Mix.Task.run("app.start")  # ensures your app code is loaded

Benchee.run(%{
  "add/2 small" => fn -> Demo.Math.add(2, 3) end,
  "add/2 bigger" => fn -> Demo.Math.add(2_000, 3_000) end
})
