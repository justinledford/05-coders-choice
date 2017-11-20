defmodule Cracker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cracker,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Cracker.Application, [] },
      env: [routing_table: [client: :"client@localhost",
                            worker1: :"worker1@localhost",
                            worker2: :"worker2@localhost"]]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
    ]
  end
end
