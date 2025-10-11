defmodule Hf1.MixProject do
  use Mix.Project

  def project do
    [
      app: :hf1,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()       # <— add this
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      dialyzer: ["dialyzer"],
      bench: ["run bench/bench.exs"]
    ]
  end
end
