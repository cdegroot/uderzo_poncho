defmodule SvgParserTest do
  use ExUnit.Case
  doctest SvgParser

  use SvgParser.Elems

  @circle """
  <?xml version="1.0" encoding="UTF-8" ?>
  <svg height="100" width="100">
    <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
  </svg>
  """

  test "parses basic SVG" do
    assert SvgParser.parse(@circle) == %Svg{
      height: 100.0,
      width:  100.0,
      contents: [%Circle{c: %Point{x: 50.0, y: 50.0}, r: %Scalar{l: 40.0},
                         stroke: %Colour{r: 0.0, g: 0.0, b: 0.0, a: 0.0},
                         stroke_width: %Scalar{l: 3.0},
                         fill: %Colour{r: 1.0, g: 0.0, b: 0.0, a: 0.0}}]}
  end

  test "normalizes SVG" do
    svg = SvgParser.parse(@circle)
    assert SvgParser.normalize(svg) == %Svg{
      height: 1.0,
      width: 1.0,
      contents: [%Circle{c: %Point{x: 0.5, y: 0.5}, r: %Scalar{l: 0.4},
                         stroke: %Colour{r: 0.0, g: 0.0, b: 0.0, a: 0.0},
                         stroke_width: %Scalar{l: 0.03},
                         fill: %Colour{r: 1.0, g: 0.0, b: 0.0, a: 0.0}}]}
  end

  test "scales an SVG" do
    svg = @circle
    |> SvgParser.parse()
    |> SvgParser.normalize()
    assert SvgParser.scale(svg, 0.5, 0.1) == %Svg{
      height: 0.5,
      width: 0.1,
      contents: [%Circle{c: %Point{x: 0.25, y: 0.05}, r: %Scalar{l: 0.12},
                         stroke: %Colour{r: 0.0, g: 0.0, b: 0.0, a: 0.0},
                         stroke_width: %Scalar{l: 0.009},
                         fill: %Colour{r: 1.0, g: 0.0, b: 0.0, a: 0.0}}]}
  end

  test "moves an SVG" do
    svg = @circle
    |> SvgParser.parse()
    |> SvgParser.normalize()
    |> SvgParser.scale(0.5, 0.1)
    assert SvgParser.move(svg, 0.1, 0.1) == %Svg{
      height: 0.5,
      width: 0.1,
      # TODO do nice float comparisons because this'll likely break cross-platform
      contents: [%Circle{c: %Point{x: 0.35, y: 0.15000000000000002}, r: %Scalar{l: 0.12},
                         stroke: %Colour{r: 0.0, g: 0.0, b: 0.0, a: 0.0},
                         stroke_width: %Scalar{l: 0.009},
                         fill: %Colour{r: 1.0, g: 0.0, b: 0.0, a: 0.0}}]}
  end
end
