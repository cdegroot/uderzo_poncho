defmodule Uderzo.Mixfile do
  use Mix.Project

  def project do
    [ app: :uderzo,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      name: "Uderzo",
      source_url: "https://github.com/cdegroot/uderzo_poncho",
      make_env: make_env(),
      compilers: Mix.compilers # ++ [:elixir_make]
    ]
  end

  def docs do
    [ extras: [
        "docs/Clixir.md"]]
  end

  def application do
    [ mod: {Uderzo, []},
      extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [ {:elixir_make, "~> 0.4", runtime: false},
      {:clixir, path: "../clixir"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.3", only: [:dev, :test]}]
  end

  defp description() do
    "A native UI package for Elixir employing NanoVG/OpenGL ES"
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"}
      _ ->
        %{}
    end
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
