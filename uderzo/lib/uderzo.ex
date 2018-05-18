defmodule Uderzo do
  @moduledoc """
  Uderzo application.

  This application basically just starts the supervisor that starts
  the genserver that talks to the `uderzo` executable.
  """

  use Application

  def start(_type, _args) do
    children = [
      ClixirServer
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
