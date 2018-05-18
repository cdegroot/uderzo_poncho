defmodule UderzoDemoNerves.Application do
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    Uderzo.Demo.run
  end
end
