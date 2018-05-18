defmodule Clixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :clixir,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      name: "Clixir",
      source_url: "https://github.com/cdegroot/uderzo_poncho"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:mix_test_watch, "~> 0.3", only: [:dev, :test]}]
  end

  defp description, do: "A safe way to extend Elixir with C functions"

  def docs do
    [ extras: [
        "docs/Clixir.md"]]
  end

  defp package() do
    [ # These are the default files included in the package
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*"],
      maintainers: ["Cees de Groot"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/cdegroot/uderzo_poncho"}]
  end
end
