defmodule ClixirExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :clixir_example,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      make_env: make_env(),
      compilers: Mix.compilers ++ [:clixir, :elixir_make]
    ]
  end

  # TODO repeated from clixir's mix.exs. Make reusable somehow?
  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib",
          "MIX_ENV" => "#{Atom.to_string(Mix.env())}"}
      _ ->
        %{}
    end
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExampleApplication, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [ {:clixir, path: "../clixir"}
    ]
  end
end
