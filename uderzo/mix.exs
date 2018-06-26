defmodule Uderzo.Mixfile do
  use Mix.Project

  def project do
    [ app: :uderzo,
      version: "0.5.3",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      name: "Uderzo",
      source_url: "https://github.com/cdegroot/uderzo_poncho",
      make_env: &make_env/0,
      compilers: Mix.compilers ++ [:clixir, :elixir_make]
    ]
  end

  def docs do
    [ extras: [
        "docs/overview.md"
    ]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [clixir_dep(Mix.env),
     {:ex_doc, "~> 0.16", runtime: false},
     {:mix_test_watch, "~> 0.3", only: [:dev, :test]}]
  end

  def clixir_dep(:prod), do: {:clixir, "~> 0.3.2"}
  def clixir_dep(_), do: {:clixir, path: "../clixir"}

  defp description() do
    "A native UI package for Elixir employing NanoVG/OpenGL ES"
  end

  defp make_env() do
    erl_env = case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib",
          }
      _ ->
        %{}
    end
    erl_env
    |> Map.put("MIX_ENV", "#{Mix.env}")
    |> Map.put("CLIXIR_DIR", Mix.Project.build_path <> "/lib/clixir/priv")
    |> Map.put("UDERZO_DIR", "priv/")
  end

  defp package() do
    [ # These are the default files included in the package
      files: [
        "lib",
        "c_src",
        "priv/*.ttf",
        "mix.exs",
        "Makefile",
        "setup.mk",
        "README*",
        "LICENSE*"],
      maintainers: ["Cees de Groot"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/cdegroot/uderzo_poncho"}]
  end
end
