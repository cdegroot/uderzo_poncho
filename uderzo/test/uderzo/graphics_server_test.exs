defmodule Uderzo.GraphicsServerTest do
  use ExUnit.Case, async: true

  import Uderzo.Bindings
  import Uderzo.Thermostat

  test "Bindings work for a basic demo" do
    glfw_create_window(640, 480, "Another demo window", self())
    receive do
      {:glfw_create_window_result, window} ->
        IO.puts("Window created, handle is #{inspect window}")
        tim_init()
        IO.puts("\n")
        paint_a_frame(window)
        Process.sleep(1_000)
        glfw_destroy_window(window)
      msg ->
        IO.puts("Received message #{inspect msg}")
    end
    Process.sleep(1_000)
  end

  @base :erlang.system_time(:nanosecond)

  defp paint_a_frame(window) do
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, mx, my, win_width, win_height} ->
        t = (:erlang.system_time(:nanosecond) - @base) / 1_000_000_000
	      tim_render(mx, my, win_width, win_height, t)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            IO.puts("Frame complete")
        end
    end
  end
end
