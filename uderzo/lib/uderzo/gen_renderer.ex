defmodule Uderzo.GenRenderer do
  @moduledoc """
  Generic rendering code. This will start a process that will render a frame
  at a regular rate in a window of the indicated size. Rendering the frame is
  done by calling a callback with the current window
  size and height and the current mouse pointer position.

  `GenRenderer` is using `GenServer` internally and is thus OTP compatible.

  Usually, if you want to use Uderzo, this is the module you want to build
  around. See also the examples and demos in the repository.

  The basic usage of GenRenderer is the same as GenServer: you `use` the
  module, supply a `render_frame/5` callback and an optional `init_renderer/1` callback. There
  are just more arguments than with GenServer ;-). Short skeleton:

  ```
  defmodule MyRenderer do
    use Uderzo.GenRenderer

  def start_link(...) do
    Uderzo.GenRenderer.start_link(__MODULE__, "My Demo", 800, 600, 60, [], name: __MODULE__)
  end

  def init_renderer([]) do
    {:ok, %{some: :state}}
  end

  def render_frame(window_width, window_height, mouse_x, mouse_y, state) do
    ... Paint your frame here ...
    {:ok, state}
  end
  ```

  One important difference with GenServer is that the `init_renderer/1` callback isn't
  called during start time but rather as soon as Uderzo is initialized. This means
  that you can call functions to load fonts, etcetera, at initialization time.

  Note that once called, GenRenderer just goes off and does rendering. There's no
  requirement to interact with it further, although you can set the user state directly,
  forcing a redraw if desired.
  """

  @doc """
  The (optional) init callback. It either returns `:ok` and the initial state, or
  an error which will cause the GenRenderer to bail out.
  """
  @callback init_renderer(args :: term) :: {:ok, term} | :error

  @doc """
  The rendering function. This is called `fps` times per second. It should try to
  complete quickly so that frames aren't skipped.
  """
  @callback render_frame(window_width :: float, window_height :: float,
    mouse_x :: float,
    mouse_y :: float,
    state ::term) :: {:ok, term} | :error

  defmacro __using__(_opts) do
    quote do
      @behaviour Uderzo.GenRenderer

      @doc false
      def init_renderer(args) do
        {:ok, args}
      end

      @doc false
      def render_frame(_ww, _wh, _mx, _my, _state) do
        # TODO compile-time check? Just silently let this be called?
      end

      defoverridable [init_renderer: 1, render_frame: 5]
    end
  end

  use GenServer
  import Uderzo.Bindings

  require Logger

  defmodule State do
    defstruct [:title, :window_width, :window_height, :target_fps,
              :window, :user_state, :user_module, :rendering]
  end

  @doc """
  Start a GenRenderer with the indicated window height, width and title and
  the target FPS.

  The target_fps is a target, much rests on the speed of the rendering function
  for the real fps.

  The final argument, `genserver_opts`, is just passed on to `GenServer.start_link/3`.

  Returns `GenServer.on_start`.
  """
  def start_link(module, title, window_width, window_height, target_fps, args, genserver_opts \\ []) do
    GenServer.start_link(__MODULE__,
      [title, window_width, window_height, target_fps, args, module],
      Keyword.merge([name: Uderzo.GenRenderer], genserver_opts))
  end

  @doc """
    Set the user_state portion of %State{}. This is the data that gets passed into render.
    Calling this has the side effect of redrawing the screen.
  """
  def set_user_state(new_state) do
    GenServer.call(Uderzo.GenRenderer, {:set_user_state, new_state})
  end

  @doc """
    Get the user_state portion of %State{}. This is the data that gets passed into render.
  """
  def get_user_state() do
    GenServer.call(Uderzo.GenRenderer, :get_user_state)
  end

  # Just call the uderzo_init() method and let messages from Uderzo drive the rest.
  def init([title, window_width, window_height, target_fps, user_state, user_module]) do
    uderzo_init(self())
    {:ok, %State{title: title, window_width: window_width, window_height: window_height,
      target_fps: target_fps, user_state: user_state, user_module: user_module, rendering: false}}
  end

  # Get the user state .
  def handle_call(:get_user_state, _from, state) do
    {:reply, state.user_state, state}
  end

  # Set the user state directly and trigger a screen redraw.
  def handle_call({:set_user_state, new_state}, _from, state) do
    state = %State{state | user_state: new_state}
    send(self(), :render_next)
    {:reply, state, state}
  end

  # On uderzo_init completion, we receive :uderzo_initialized and can therefore create a window.
  def handle_info(:uderzo_initialized, state) do
    glfw_create_window(state.window_width, state.window_height, state.title, self())
    {:noreply, state}
  end

  # On window creation completion, we can kick off the rendering loop.
  # However, first we have promised to talk to the user initialization code
  def handle_info({:glfw_create_window_result, window}, %{target_fps: target_fps} = state) do
    {:ok, user_state} = state.user_module.init_renderer(state.user_state)
    int = Kernel.trunc(1_000 / target_fps)
    send(self(), :render_next)
    :timer.send_interval(int, self(), :render_next)
    {:noreply, %State{state | window: window, user_state: user_state}}
  end

  def handle_info(:render_next, %State{rendering: true} = state) do
    Logger.warn("skipping frame, render already in progress")
    {:noreply, state}
  end

  def handle_info(:render_next, state) do
    uderzo_start_frame(state.window, self())
    {:noreply, %{state | rendering: true}}
  end

  # Uderzo tells us we're good to do the actual rendering
  def handle_info({:uderzo_start_frame_result, mx, my, win_width, win_height}, state) do
    {:ok, user_state} = state.user_module.render_frame(win_width, win_height, mx, my, state.user_state)
    uderzo_end_frame(state.window, self())
    {:noreply, %State{state | user_state: user_state}}
  end

  # And finally, the frame is rendered. Schedule the next frame
  def handle_info({:uderzo_end_frame_done, _window}, state) do
    {:noreply, %{state | rendering: false}}
  end
end
