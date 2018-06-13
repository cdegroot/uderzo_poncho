defmodule SvgParser.Elems do
  @moduledoc """
  SVG elements, returned in the SVG structure.
  """

  defmodule Svg do
    defstruct [:height, :width, :contents]
  end

  defmodule Colour do
    defstruct [:r, :g, :b, :a]
  end

  defmodule Point do
    defstruct [:x, :y]
  end

  defmodule Scalar do
    defstruct [:l]
  end

  defmodule Circle do
    defstruct [:c, :r, :stroke, :stroke_width, :fill]
  end

  @doc """
  Use the `use` form to import the works in one go.
  """
  defmacro __using__(_) do
    modules = [Svg, Colour, Point, Scalar, Circle]
    Enum.map(modules, fn(m) ->
      quote do
        alias(unquote(m))
      end
    end)
  end

end
