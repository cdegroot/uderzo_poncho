defmodule ClixirTest do
  use ExUnit.Case, async: true

  import Clixir

  # Example invocation. This should compile.
  def_c glfw_get_cursor_pos(window, pid) do
    cdecl "GLFWwindow *": window
    cdecl erlang_pid: pid
    cdecl double: [mx, my]
    glfwGetCursorPos(window, &mx, &my)
    {pid, {mx, my}}
  end

  test "embedded C code works" do
    ast = quote do
      cdecl "char *": title
      cdecl long: [length, width, height]
      cdecl erlang_pid: pid
      cdecl "GLFWWindow *": window
      window = glfwCreateWindow(width, height, title, NULL, NULL)
      if vg == NULL do
        vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
        assert(vg != NULL)
      end
      if window != NULL do
        {pid, {:ok, window}}
      else
        {pid, {:error, "Could not create window"}}
      end
    end
    {:__block__, _, exprs} = ast

    {hdr, c_string} = make_c(:glfw_create_window, [:width, :height, :title, :pid], exprs)

    assert hdr == "// Generated code for glfw_create_window do not edit!"
    assert c_string == """
static void _dispatch_glfw_create_window(const char *buf, unsigned short len, int *index) {
    long height;
    long length;
    erlang_pid pid;
    char title[BUF_SIZE];
    long title_len;
    long width;
    GLFWWindow * window;
    assert(ei_decode_long(buf, index, &width) == 0);
    assert(ei_decode_long(buf, index, &height) == 0);
    assert(ei_decode_binary(buf, index, title, &title_len) == 0);
    title[title_len] = '\\0';
    assert(ei_decode_pid(buf, index, &pid) == 0);
    window = glfwCreateWindow(width, height, title, NULL, NULL);
    if (vg == NULL) {
        vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
        assert(vg != NULL);
    }
    if (window != NULL) {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_atom(response, &response_index, "ok");
        ei_encode_longlong(response, &response_index, (long long) window);
        write_response_bytes(response, response_index);
    } else {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_atom(response, &response_index, "error");
        ei_encode_string(response, &response_index, "Could not create window");
        write_response_bytes(response, response_index);
    }
}
"""
  end
end
