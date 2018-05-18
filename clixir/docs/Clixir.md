# Clixir

_Disclaimer: for now, this is design documentation, actual implementation may have differences. See
the code, `lib/uderzo/clixir.ex` and the associated test for actuals_

We write the C code in Elixir and use macros to generate both the Elixir bindings
and the C code. This idea was blatantly stolen from Squeak Smalltalk. As we aim
for a very low level interface, all the functions will have the same structure in
C: unmarshall arguments, make call, marshall return values; so "Clixir" can start
out simple.

```elixir

  defgfx glfw_get_cursor_pos(window, pid) do
    cdecl "GLFWwindow *": window
    cdecl erlang_pid: pid
    cdecl double: [mx, my]
    glfwGetCursorPos(window, &mx, &my)
    {pid, {mx, my}}
  end
```

will result in this Elixir code (both a regular and a blocking synchronous version
are generated, although I think the sync version shouldn't be used ;-)):

```elixir
  @spec glfw_get_cursor_pos(integer, pid) :: none
  def glfw_get_cursor_pos(window, pid) do
    GraphicsServer.send_command(GraphicsServer, {:glfw_get_cursor_pos, window, pid})
  end

  @spec glfw_get_cursor_pos_s(integer) :: {float, float}
  def glfw_get_cursor_pos(window) do
    glfw_get_cursor_pos(window, self)
    receive do
      {mx, my} when is_float(mx) and is_float(my) -> {mx, my}
    end
  end
```

and the following C code:

```c
static void _dispatch_glfw_get_cursor_pos(const char *buf, unsigned short len, int *index) {

  GLFWwindow *window;
  erlang_pid pid;
  double mx, my;

  assert(ei_decode_longlong(buf, index, (long long *) &window) == 0);
  assert(ei_decode_pid(buf, index, &pid) == 0);

  glfwGetCursorPos(window, &mx, My);

  ei_encode_version(response, &response_index);
  ei_encode_tuple_header(response, &response_index, 2);
  ei_encode_pid(response, &response_index, &pid);
  ei_encode_tuple_header(response, &response_index, 2);
  ei_encode_double(response, &response_index, mx);
  ei_encode_double(response, &response_index, my);

  write_response_bytes(response, response_index);
}
```

The idea is to write a Clixir wrapper for every NanoVG/GLFW/OpenGL function under the sun.

## Performance

Performance of the protocol should be very good, for the following reasons:

* the `ei_decode_..` family seems to do very little copying and is efficient by keeping
  a pointer in a buffer that moves up; ideally, this means that a message is scanned in
  a single loop the length of the message;
* dispatching is done using a `gperf` generated hashtable. These perfect hashtables are
  very fast, usually requiring just two memory lookups to find the function pointer to 
  dispatch to.
* most of the tight rendering code is (and should be kept) async - you're just sending
  messages over a local file descriptor pipe and keeping the pipe filled when drawing a
  frame should be very easy. 

