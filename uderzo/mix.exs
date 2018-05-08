defmodule Uderzo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :uderzo,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      compilers: Mix.compilers ++ [:elixir_make]
    ]
  end

  def docs do
    [
      extras: [
        "docs/Clixir.md"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Uderzo, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
