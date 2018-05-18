defmodule Clixir.Application do
  @moduledoc """
  Clixir application. This starts the Clixir wrapper server that monitors
  and talks to the `clixir` executable.
  """

  def start(_type, _args) do
    Supervisor.start_link([Clixir.Server], strategy: :one_for_one)
  end
end
