defmodule UderzoDemoNerves.Application do
  @moduledoc false

  #@target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    IO.puts("starting up. Sleeping a bit to stabilize drivers")
    Process.sleep(5_000)
    IO.puts("starting demo")
    Uderzo.Demo.run
  end
end
