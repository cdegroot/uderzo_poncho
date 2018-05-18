defmodule ExampleApplication do
  use Application

  def start(_type, _args) do
    # The genserver is already running, so let's say something nice.
    Example.hello("world")
    Process.sleep(1000)
    {:ok, self()}
  end
end
