defmodule Uderzo.Demo do
  @moduledoc """
  Run a very simple thermostat display demo using Uderzo's
  `Uderzo.GenRenderer` abstraction.
  """
  use Uderzo.GenRenderer
  import UderzoExample.Thermostat
  require Logger

  def run do
    t_start = timestamp()
    Uderzo.GenRenderer.start_link(__MODULE__, "Uderzo Demo", 800, 600, 5, {t_start, 0})
    Process.sleep(5000) # Let it run for 5 seconds, then we bail out
  end

  def init_renderer({t_start, frame}) do
    tim_init()
    {:ok, {t_start, frame}}
  end

  def render_frame(win_width, win_height, _mx, _my, {t_start, frame}) do
    if rem(frame, 100) == 0 do
      Logger.info("frame #{frame}")
    end
    t = timestamp() - t_start
    tim_render(win_width, win_height, t)
    {:ok, {t_start, frame + 1}}
  end

  defp timestamp, do: :erlang.system_time(:nanosecond) / 1_000_000_000.0
end
