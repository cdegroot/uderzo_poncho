# UderzoSvg

An Uderzo module to draw SVG files. The idea is that an SVG file gets parsed
into a usable structure (see the `svg_parser` sibling application), and then two
things can happen:

* The SVG is interpreted at run-time to allow icons, etcetera, to be displayed. This
  is a reasonable approach, but slow and boring;
* The SVG is compiled to Clixir code which then generates an equivalent C routine. This
  is really fast and not boring.

An SVG typically comes with a width and height and inside all coordinates are relative. In
the parser, we convert any coordinate to a Point and any scalar size to a Scalar. This
flags us for coordinate conversions. The process for compiling SVG therefore becomes:

    SVG -> transform(add mapping functions) -> emit def_c -> Clixir -> C code

where the C code basically is "draw this SVG at this position with this relative size" (in
terms of OpenGL {0, 1} coordinates) and then the scaling happens on the fly in the C
code (which is plenty fast).

The end result is basically that you can call SVG graphs as sprites of a sort from Elixir
and the heavy lifting happens in C.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `uderzo_svg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:uderzo_svg, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/uderzo_svg](https://hexdocs.pm/uderzo_svg).
