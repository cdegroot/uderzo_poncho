defmodule Clixir.Application do
  @moduledoc """
  Clixir application. This starts the Clixir wrapper server that monitors
  and talks to the `clixir` executable.
  """

  if Mix.env == :test do
    def start(_type, _args) do
      {:ok, self()}
    end
  else
    def start(_type, _args) do
      Supervisor.start_link([Clixir.Server], strategy: :one_for_one)
    end
  end
end
