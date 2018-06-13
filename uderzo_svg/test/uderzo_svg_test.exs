defmodule UderzoSvgTest do
  use ExUnit.Case
  doctest UderzoSvg

  @clixir_header "uderzo_svg"

  use UderzoSvg

  # For now, we scale and move during definition. You can have multiple "sprites"
  # and it is fast and simple. We'll tackle moving them around later ;-)
  def_svg(:small_circle, 0.5, 0.1, 0.1, 0.1, """
  <?xml version="1.0" encoding="UTF-8" ?>
  <svg height="100" width="100">
  <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
  </svg>
  """)

  test "converts basic SVG to C code" do
    # Check that we got a module compiled in.
    assert Keyword.get(__info__(:functions), :small_circle) == 0
  end
end
