defmodule UderzoTest do
  use ExUnit.Case, async: true

  import Uderzo.Bindings

  @tag timeout: 5000
  test "Bindings work for a basic demo" do
    IO.puts("Testing!!!")
    uderzo_init(self())
    receive do
      _msg ->
        glfw_create_window(640, 480, "Another demo window", self())
        receive do
          {:glfw_create_window_result, window} ->
            IO.puts("Window created, handle is #{inspect window}")
            paint_a_frame(window)
            Process.sleep(1_000)
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received message #{inspect msg}")
        end
    end
    Process.sleep(1_000)
  end

  @base :erlang.system_time(:nanosecond)

  defp paint_a_frame(window) do
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, _mouse_x, _mouse_y, _win_width, _win_height} ->
        _ = (:erlang.system_time(:nanosecond) - @base) / 1_000_000_000
	      # This is where you'd render an actual frame. _ above would provide you a frame timer of sorts for animations etc
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            IO.puts("Frame complete")
        end
    end
  end
end
