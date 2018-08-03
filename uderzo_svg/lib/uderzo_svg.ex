defmodule UderzoSvg do
  @moduledoc """
  SVG support for Uderzo. This file defines macros to deal with SVG files.
  """

  use SvgParser.Elems # TODO maybe move this to `use SvgParser`?
  defmacro __using__(_opts) do
    quote do
      use Clixir
      import UderzoSvg
    end
  end


  defmacro def_svg(name, xs, ys, x, y, svg_data) do
    svg = parse_svg(svg_data, xs, ys, x, y)
    clixir_code = make_clixir(svg)
    quote do
      def_c unquote(name)() do
        unquote_splicing(clixir_code)
      end
    end
  end


  def parse_svg(svg_data, xs, ys, x, y) do
    svg_data
    |> SvgParser.parse()
    |> SvgParser.normalize()
    |> SvgParser.scale(xs, ys)
    |> SvgParser.move(x, y)
  end

  def make_clixir(svg) do
    svg.contents
    |> Enum.map(&make_clixir_for_elem/1)
  end

  def make_clixir_for_elem(%Circle{} = circle) do
    quote do
      nvgBeginPath(vg)
      nvgCircle(vg, unquote(circle.c.x), unquote(circle.c.y), unquote(circle.r.l))
      nvgFillColor(vg, nvgRGBA(unquote(circle.fill.r), unquote(circle.fill.g),
            unquote(circle.fill.b), unquote(circle.fill.a)))
      nvgFill(vg)
      nvgStrokeColor(vg, nvgRGBA(unquote(circle.stroke.r), unquote(circle.stroke.g),
        unquote(circle.stroke.b), unquote(circle.stroke.a)))
      nvgStrokeWidth(vg, unquote(circle.stroke_width.l))
      nvgStroke(vg)
    end
  end

  def make_clixir_for_elem(unknown) do
    raise "Unknown SVG element #{inspect unknown}"
  end
end
