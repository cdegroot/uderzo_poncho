defmodule Uderzo.Bindings do
  @moduledoc """
  Uderzo Elixir->C bindings in Clixir. Note that for demo purposes,
  this is a hodgepodge of various modules - NanoVG, GLFW, utility
  methods, demo methods; there's nothing however that precludes
  a clean separation. Yet ;-)
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

  # A sample thermostat display.
  def temp(t) do
    # Fake the temperature
    25 * :math.sin(t / 10)
  end

  def tim_init() do
    base_dir = Application.app_dir(:uderzo, ".")
    priv_dir = Path.absname("priv", base_dir)

    create_font("sans", Path.join(priv_dir, "SourceCodePro-Regular.ttf"))
  end

  defgfx create_font(name, file_name) do
    cdecl "char *": [name, file_name]
    cdecl int: retval

    assert(nvgCreateFont(vg, name, file_name) >= 0)
  end

  def tim_render(mouse_x, mouse_y, win_width, win_height, t) do
    inside = temp(t)
    outside = temp(t - 10)
    burn = inside < outside
    draw_inside_temp(inside, win_width, win_height)
    draw_outside_temp(outside, win_width, win_height)
    draw_burn_indicator(burn, win_width, win_height)
  end

  defp left_align(x), do: 0.1 * x
  defp display_temp(t), do: "#{:erlang.float_to_binary(t, [decimals: 1])}°C"

  def draw_inside_temp(temp, w, h) do
    left_align = left_align(w)
    draw_small_text("Inside temp", left_align, 0.1 * h)
    draw_big_text(display_temp(temp), left_align, 0.14 * h)
  end
  def draw_outside_temp(temp, w, h) do
    left_align = left_align(w)
    draw_small_text("Outside temp", left_align, 0.3 * h)
    draw_big_text(display_temp(temp), left_align, 0.34 * h)
  end
  def draw_burn_indicator(burn = true, w, h), do: show_flame(w, h)
  def draw_burn_indicator(burn = false, w, h), do: nil

  def draw_small_text(t, x, y), do: draw_text(t, String.length(t), 16.0, x, y)
  def draw_big_text(t, x, y), do: draw_text(t, String.length(t), 40.0, x, y)

  defgfx show_flame(w, h) do
    cdecl double: [w, h]
    fprintf(stderr, "Here is where we draw a flame..;")
  end

  defgfx draw_text(t, tl, sz, x, y) do
    cdecl "char *": t
    cdecl long: tl
    cdecl double: [sz, x, y]

    nvgFontSize(vg, sz)
    nvgFontFace(vg, "sans")
    nvgTextAlign(vg, NVG_ALIGN_LEFT|NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
    nvgText(vg, x, y, t, t + tl)
  end
end

#  LocalWords:  GLFWwindow
