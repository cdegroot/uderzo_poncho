defmodule Uderzo.Bindings do
  @moduledoc """
  Uderzo Elixir->C bindings in Clixir. Note that for demo purposes,
  this is a hodgepodge of various modules - NanoVG, GLFW, utility
  methods, demo methods; there's nothing however that precludes
  a clean separation. Yet ;-)
  """
  use Clixir

  @clixir_header "uderzo"

  @doc """
  Initialize Uderzo. Calling this is mandatory.

  Upon completion, `pid` will receive `:uderzo_initialized`, after which
  drawing can commence.
  """
  def_c uderzo_init(pid) do
    cdecl erlang_pid: pid

    uderzo_init()

    {pid, :uderzo_initialized}
  end

  # If we are on something that smells like a Nerves target, then we are going to assume
  # a compile for Broadcom's VideoCore.
  if :erlang.system_info(:system_architecture) == 'armv7l-unknown-linux-gnueabihf' or
     System.get_env("MIX_TARGET") != nil do
    IO.puts "Compiling for Nerves!"

    # Fake GLFW code ;-)
    def_c glfw_create_window(width, height, title, pid) do
      cdecl "char *": title
      cdecl long: [length, width, height]
      cdecl erlang_pid: pid

      {pid, {:glfw_create_window_result, 42}}
    end

    def_c glfw_destroy_window(window) do
      cdecl long: window  # fake handle, ignore
      assert(window == 42)
    end

    # Note that we can optimize start frame for a fixed display like on an RPi3,
    # but for ease of development we stay compatible with variable-sized windows
    # for now. Later on we need to feed the result of the VideoCore screen size
    # into this thing.
    def_c uderzo_start_frame(window, pid) do
      cdecl long: window # Fake window
      cdecl erlang_pid: pid
      cdecl int: [winWidth, winHeight, fbWidth, fbHeight]
      cdecl double: [mouse_x, mouse_y, win_width, win_height, t, pxRatio]

      #glBindFramebuffer(GL_FRAMEBUFFER, 0)

      # Update and render
      glViewport(0, 0, 720, 480)
      glClearColor(0.3, 0.3, 0.32, 1.0)
      glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)

      glEnable(GL_BLEND)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glEnable(GL_CULL_FACE)
      glEnable(GL_DEPTH_TEST)

      nvgBeginFrame(vg, 720, 480, 1.0)

      {pid, {:uderzo_start_frame_result, 0.0, 0.0, 720.0, 480.0}}
    end

    def_c uderzo_end_frame(window, pid) do
      cdecl long: window  # fake handle, ignore
      cdecl erlang_pid: pid

      nvgEndFrame(vg)
      eglSwapBuffers(state.display, state.surface)

      # TODO I guess we could copy straight from the buffer without swapping..?
      uderzo_vcfbcp_copy()

      {pid, :uderzo_end_frame_done}
    end
  else

    # GLFW code

    @doc """
    Create a window using the GLFW library. The window will have the indicated
    height and width.

    Upon completion, one of two results will be sent to `pid`:
    * `{:error, error_message}` when an error occurs
    * `{:glfw_create_window_result, window_handle}` on success.
    The `window_handle` must be stored and passed into later drawing operations.

    On the RaspberryPi 3 VideoCore target, this function still needs to be called
    even though an actual window is not created.
    """
    def_c glfw_create_window(width, height, title, pid) do
      cdecl "char *": title
      cdecl long: [length, width, height]
      cdecl erlang_pid: pid
      cdecl "GLFWwindow *": window
      window = glfwCreateWindow(width, height, title, NULL, NULL)

      # There is certain stuff that only can be done when we have a GLFW window.
      # Do that now.

      glfwMakeContextCurrent(window)
      glfwSwapInterval(0)
      if vg == NULL do
        vg = nvgCreateGL2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
        assert(vg != NULL)
      end
      if window != NULL do
        {pid, {:glfw_create_window_result, window}}
      else
        # TODO this is sent as an atom instead of a binary.
        {pid, {:error, "Could not create window"}}
      end
    end

    @doc """
    Destroy the indicated window. `window` is a window handle returned from
    `glfw_create_window/4`.
    """
    def_c glfw_destroy_window(window) do
      cdecl "GLFWwindow *": window
      glfwDestroyWindow(window)
    end

    # Utility code

    @doc """
    Setup the start of a frame. This function combines several things
    that should happen at the start of every frame: get the window
    size, the cursor position, etcetera, then set the viewport
    and clear the framebuffer.

    When this function completes, it sends the mouse location
    and window dimensions back:

    ```
    {:uderzo_start_frame_result, mouse_x, mouse_y, win_width, win_height}
    ```

    It's recommended to wait for this message and then send the rest of the frame drawing
    commands.
    """
    def_c uderzo_start_frame(window, pid) do
      cdecl "GLFWwindow *": window
      cdecl erlang_pid: pid
      cdecl int: [winWidth, winHeight, fbWidth, fbHeight]
      cdecl double: [mouse_x, mouse_y, win_width, win_height, t, pxRatio]

      glfwGetCursorPos(window, &mouse_x, &mouse_y)
      glfwGetWindowSize(window, &winWidth, &winHeight)
      glfwGetFramebufferSize(window, &fbWidth, &fbHeight)
      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth / winWidth

      # Update and render
      glViewport(0, 0, fbWidth, fbHeight)
      glClearColor(0.3, 0.3, 0.32, 1.0)
      glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)

      glEnable(GL_BLEND)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glEnable(GL_CULL_FACE)
      glDisable(GL_DEPTH_TEST)

      nvgBeginFrame(vg, winWidth, winHeight, pxRatio)

      # Convert to doubles. Naming could be better ;-)
      win_width = winWidth
      win_height = winHeight

      {pid, {:uderzo_start_frame_result, mouse_x, mouse_y, win_width, win_height}}
    end

    @doc """
    Complete a frame. Similarly to `uderzo_start_frame/2`, this
    does some housekeeping and eventually a buffer swap to
    display the frame. When complete, this sends the atom
    `:uderzo_end_frame_done` to `pid`. This can be used to
    synchronize on complete frames.

    On the Raspberry Pi 3 this function will also copy the
    contents of the frame to the secondary framebuffer, `/dev/fb1`,
    if available. This secondary framebuffer usually corresponds with a
    correctly configured HAT display (see the [Nerves demo in the Uderzo
    source repository](https://github.com/cdegroot/uderzo_poncho/tree/master/uderzo_demo_nerves) for an example).
    """
    def_c uderzo_end_frame(window, pid) do
      cdecl "GLFWwindow *": window
      cdecl erlang_pid: pid

      nvgEndFrame(vg)
      glEnable(GL_DEPTH_TEST)

      glfwSwapBuffers(window)
      glfwPollEvents()

      {pid, :uderzo_end_frame_done}
    end
  end
end

#  LocalWords:  GLFWwindow
