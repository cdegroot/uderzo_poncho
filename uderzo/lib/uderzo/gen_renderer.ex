defmodule Uderzo.GenRenderer do
  @moduledoc """
  Generic rendering code. This will start a process that will render a frame
  at a regular rate in a window of the indicated size. Rendering the frame is
  done by calling a callback with the current window
  size and height and the current mouse pointer position.

  `GenRenderer` is using `GenServer` internally and is thus OTP compatible.

  Usually, if you want to use Uderzo, this is the module you want to build
  around. See also the examples and demos in the repository.
  """
  use GenServer
  import Uderzo.Bindings

  defmodule State do
    defstruct [:title, :window_width, :window_height, :target_fps, :rendering_function,
              :window, :ntt]
  end

  @doc """
  Start a GenRenderer with the indicated window height, width and title and
  the indicated rendering function. The rendering function has arity 4 and will
  receive the window width, height, and current mouse pointer position as x, y.

  The target_fps is a target, much rests on the speed of the rendering function
  for the real fps.

  The final argument, `genserver_opts`, is just passed on to `GenServer.start_link/3`.

  Returns `GenServer.on_start`.
  """
  def start_link(title, window_width, window_height, target_fps, rendering_function, genserver_opts \\ []) do
    GenServer.start_link(__MODULE__,
      [title, window_width, window_height, target_fps, rendering_function],
      genserver_opts)
  end

  # Just call the uderzo_init() method and let messages from Uderzo drive the rest.
  def init([title, window_width, window_height, target_fps, rendering_function]) do
    uderzo_init(self())
    {:ok, %State{title: title, window_width: window_width, window_height: window_height,
      target_fps: target_fps, rendering_function: rendering_function}}
  end

  # On uderzo_init completion, we receive :uderzo_initialized and can therefore create a window
  def handle_info(:uderzo_initialized, state) do
    glfw_create_window(state.window_width, state.window_height, state.title, self())
    {:noreply, state}
  end

  # On window creation completion, we can kick off the rendering loop.
  def handle_info({:glfw_create_window_result, window}, state) do
    send(self(), :render_next)
    {:noreply, %State{state | window: window}}
  end

  # We should render a frame. Calculate right away when the _next_ frame
  # should start and tell Uderzo we're beginning a frame
  def handle_info(:render_next, state) do
    ntt = next_target_time(state.target_fps)
    uderzo_start_frame(state.window, self())
    {:noreply, %State{state | ntt: ntt}}
  end

  # Uderzo tells us we're good to do the actual rendering
  def handle_info({:uderzo_start_frame_result, mx, my, win_width, win_height}, state) do
    state.rendering_function.(win_width, win_height, mx, my)
    uderzo_end_frame(state.window, self())
    {:noreply, state}
  end

  # And finally, the frame is rendered. Schedule the next frame
  def handle_info(:uderzo_end_frame_done, state) do
    Process.send_after(self(), :render_next, nap_time(state.ntt))
    {:noreply, state}
  end

  def cur_time, do: :erlang.monotonic_time(:millisecond)
  def next_target_time(fps), do: cur_time() + div(1_000, fps)
  def nap_time(ntt), do: max(0, ntt - cur_time())

end
