defmodule SvgParserTest do
  use ExUnit.Case
  doctest SvgParser

  use SvgParser.Elems

  @rectangle """
  <?xml version="1.0" encoding="UTF-8" ?>
  <svg height="100" width="100">
    <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
  </svg>
  """

  test "parses basic SVG" do
    assert SvgParser.parse(@rectangle) == %Svg{
      height: 100.0,
      width:  100.0,
      root:   [%Circle{cx: 50.0, cy: 50.0, r: 40.0,
                      stroke: %Colour{r: 0.0, g: 0.0, b: 0.0, a: 0.0},
                      stroke_width: 3.0,
                      fill: %Colour{r: 1.0, g: 0.0, b: 0.0, a: 0.0}}]}
  end
end
