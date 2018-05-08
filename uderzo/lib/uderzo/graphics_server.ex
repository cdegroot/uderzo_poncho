defmodule Uderzo.GraphicsServer do
  @moduledoc """
  This wraps the `uderzo` executable and makes it accessible.
  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc """
    Holds the state:
    * `port` is the Port that `uderzo` is running under
    """
    defstruct [:port]
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Send a command.
  """
  def send_command(pid, command) do
    :ok = GenServer.cast(pid, {:send, command})
  end

  ## Callbacks

  def init([]) do
    Logger.info("Starting uderzo process")
    uderzo_bin = Application.app_dir(:uderzo, "priv/uderzo")
    port = Port.open({:spawn, uderzo_bin},
      [{:packet, 2}, :binary, :exit_status])
    {:ok, %State{port: port}}
  end

  def handle_cast({:send, command}, state) do
    bytes = :erlang.term_to_binary(command)
    Port.command(state.port, bytes)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.info(" ignore cast #{inspect msg}")
    {:noreply, state}
  end

  # Uderzo died, we die. Supervisor will fix stuff.
  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("uderzo bailed out with #{status}, exiting")
    {:stop, "uderzo exited with #{status}", state}
  end

  def handle_info({_port, {:data, data}}, state) do
    stuff = :erlang.binary_to_term(data)
    dispatch_message(stuff)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info(" ignore info #{inspect msg}")
    {:noreply, state}
  end

  defp dispatch_message({pid, response}) when is_pid(pid) do
    send(pid, response)
  end

  defp dispatch_message(stuff) do
    Logger.info("  ignore data #{inspect stuff}")
  end
end
