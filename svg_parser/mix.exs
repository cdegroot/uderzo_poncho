defmodule SvgParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :svg_parser,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:sweet_xml, "~> 0.6.5"},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false}
    ]
  end
end
