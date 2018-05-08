defmodule Uderzo.Bindings do
  @moduledoc """
  Uderzo Elixir->C bindings in Clixir. Note that for demo purposes,
  this is a hodgepodge of various modules - NanoVG, GLFW, utility
  methods, demo methods; there's nothing however that precludes
  a clean separation.
  """
  use Uderzo.Clixir

  @clixir_target "c_src/uderzo"

  defgfx comment(comment) do
    cdecl "char *": comment
    fprintf(stderr, "Got comment [%s]", comment)
  end

  if :erlang.system_info(:system_architecture) == 'armv7l-unknown-linux-gnueabihf' or
     System.get_env("MIX_TARGET") == "rpi3" do
    IO.puts "Compiling for RaspberryPi!"

    # Fake GLFW code ;-)
    defgfx glfw_create_window(width, height, title, pid) do
      cdecl "char *": title
      cdecl long: [length, width, height]
      cdecl erlang_pid: pid

      {pid, {:glfw_create_window_result, 42}}
    end

    defgfx glfw_destroy_window(window) do
      cdecl long: window  # fake handle, ignore
      assert(window == 42)
    end

    # Note that we can optimize start frame for a fixed display like on an RPi3,
    # but for ease of development we stay compatible with variable-sized windows
    # for now. Later on we need to feed the result of the VideoCore screen size
    # into this thing.
    defgfx uderzo_start_frame(window, pid) do
      cdecl long: window # Fake window
      cdecl erlang_pid: pid
      cdecl int: [winWidth, winHeight, fbWidth, fbHeight]
      cdecl double: [mouse_x, mouse_y, win_width, win_height, t, pxRatio]

      #glBindFramebuffer(GL_FRAMEBUFFER, 0)

      # Update and render
      glViewport(0, 0, 1920, 1080)
      glClearColor(0.3, 0.3, 0.32, 1.0)
      glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)

      glEnable(GL_BLEND)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glEnable(GL_CULL_FACE)
      glEnable(GL_DEPTH_TEST)

      nvgBeginFrame(vg, 1920, 1080, 1.0)

      {pid, {:uderzo_start_frame_result, 0.0, 0.0, 1920.0, 1080.0}}
    end 

    defgfx uderzo_end_frame(window, pid) do
      cdecl long: window  # fake handle, ignore
      cdecl erlang_pid: pid

      nvgEndFrame(vg)
      eglSwapBuffers(state.display, state.surface)

      {pid, :uderzo_end_frame_done}
    end
  else

    # GLFW code

    defgfx glfw_create_window(width, height, title, pid) do
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
        vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
        assert(vg != NULL)
        loadDemoData(vg, &data) # TODO hardcoding demo data in a library... bad.
      end
      if window != NULL do
        {pid, {:glfw_create_window_result, window}}
      else
        # TODO this is sent as an atom instead of a binary.
        {pid, {:error, "Could not create window"}}
      end
    end

    defgfx glfw_destroy_window(window) do
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
    and window dimensions back. It's recommended to wait for
    this message and then send the rest of the frame drawing
    commands.
    """
    defgfx uderzo_start_frame(window, pid) do
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
    Complete a frame. Similarly to `uderzo_start_frame`, this
    does some housekeeping and eventually a buffer swap to
    display the frame.
    """
    defgfx uderzo_end_frame(window, pid) do
      cdecl "GLFWwindow *": window
      cdecl erlang_pid: pid

      nvgEndFrame(vg)
      glEnable(GL_DEPTH_TEST)

      glfwSwapBuffers(window)
      glfwPollEvents()

      {pid, :uderzo_end_frame_done}
    end
  end

  # Demo code. These are some very high level calls basically just to get
  # some eyecandy going. Ideally, all the NanoVG primitives would be mapped.

  @doc """
  Very high level - this just invokes the renderDemo method.
  """
  defgfx demo_render(mx, my, width, height, t) do
    cdecl double: [mx, my, width, height, t]

    renderDemo(vg, mx, my, width, height, t, 0, &data)
  end

  # Mid-level code. If you look at the original NanoVG
  # demo code or time travel back in this Github repository,
  # you can see what happened - bit by bit, `renderDemo` gets
  # emptier and more methods appear here ;-)

  @doc """
  Draw creepy eyes following you around
  """
  defgfx draw_eyes(x, y, w, h, mx, my, t) do
    cdecl double: [x, y, w, h, mx, my, t]

    drawEyes(vg, x, y, w, h, mx, my, t)
  end
end

#  LocalWords:  GLFWwindow
