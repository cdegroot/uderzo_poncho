defmodule Uderzo.Demo do
  @moduledoc """
  Run the NanoVG Demo. This shows how we have the main loop in Elixir,
  and call "low level" stuff out in C. We're faking here a bit of course
  as `renderDemo` is hardly low level, but it sort of shows the principle.
  """
  import Uderzo.Bindings
  import UderzoExample.Thermostat
  require Logger

  def run do
    t_start = timestamp()
    uderzo_init(self())
    receive do
      msg ->
        IO.puts("result of init: #{inspect msg}")
        glfw_create_window(800, 600, "Uderzo/NanoVG Demo", self())
        receive do
          {:glfw_create_window_result, window} ->
            tim_init()
            render_loop(window, t_start)
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received unknown message #{inspect msg}")
        end
    end
  end

  defp render_loop(window, t_start, frame_counter \\ 0) do
    if rem(frame_counter, 100) == 0 do
      Logger.info("frame #{frame_counter}")
    end
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, mx, my, win_width, win_height} ->
        IO.puts("Frame done. #{win_width}x#{win_height}")
        t = timestamp() - t_start
        tim_render(win_width, win_height, t)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            Process.sleep(1000) # TODO precise fps timing.
            # And recurse...
            render_loop(window, t_start, frame_counter + 1)
        end
    end
  end

  defp timestamp, do: :erlang.system_time(:nanosecond) / 1_000_000_000.0
end
