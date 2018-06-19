defmodule Clixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :clixir,
      version: "0.3.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      make_env: make_env(),
      compilers: Mix.compilers ++ [:elixir_make],
      docs: docs(),
      description: description(),
      package: package(),
      name: "Clixir",
      source_url: "https://github.com/cdegroot/uderzo_poncho"
    ]
  end

  def application do
    [
      mod: {Clixir.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:mix_test_watch, "~> 0.3", only: [:dev, :test]},
     {:ex_doc, "~> 0.16", only: :dev, runtime: false},
     {:elixir_make, "~> 0.4.2", runtime: false}]
  end

  def make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"}
      _ ->
        %{}
    end
  end

  defp description, do: "A safe way to extend Elixir with C functions"

  def docs do
    [ extras: [
        "docs/Clixir.md"],
      main: ["clixir"]]
  end

  defp package() do
    [ # These are the default files included in the package
      files: [
        "lib",
        "c_src",
        "Makefile",
        "mix.exs",
        "README*",
        "LICENSE*"],
      maintainers: ["Cees de Groot"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/cdegroot/uderzo_poncho"}]
  end
end
