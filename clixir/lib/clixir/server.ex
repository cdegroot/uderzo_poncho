defmodule Clixir.Server do
  @moduledoc """
  This wraps the `clixir` executable and makes it accessible. For now, we hardcode the executable
  and generate one massive one until there's a use case to change this ;-)
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
    app = Application.get_env(:clixir, :application)
    Logger.info("Starting clixir process from application #{app}")
    clixir_bin = Application.app_dir(app, "priv/clixir")
    port = Port.open({:spawn, clixir_bin},
      [{:packet, 2}, :binary, :exit_status])
    {:ok, %State{port: port}}
  end

  def handle_cast({:send, command}, state) do
    Logger.debug("sending message #{inspect command}")
    bytes = :erlang.term_to_binary(command)
    Port.command(state.port, bytes)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.info(" ignore cast #{inspect msg}")
    {:noreply, state}
  end

  # Clixir died, we die. Supervisor will fix stuff.
  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("clixir bailed out with #{status}, exiting")
    {:stop, "clixir exited with #{status}", state}
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
