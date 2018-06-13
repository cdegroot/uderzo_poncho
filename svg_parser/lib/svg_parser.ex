defmodule SvgParser do
  @moduledoc """
  SvgParser public API.
  """

  @doc """
  parse an XML string into the structure defined by `SvgParser.Elems`
  """
  def parse(xml_string) do
    xml_string
    |> SvgParser.Xml.parse()
    |> SvgParser.StructMapper.map()
  end

  @doc """
  Scale an SVG by dividing everything by its height and width. Note that scalars
  will get scaled by the average of height and width.
  """
  defdelegate normalize(svg), to: SvgParser.CoordinateMapper

  @doc """
  Scale an SVG by the indicated x and y scaling factors.
  """
  defdelegate scale(svg, xs, ys), to: SvgParser.CoordinateMapper

  @doc """
  Move an SVG by the indicated x and y
  """
  defdelegate move(svg, x, y), to: SvgParser.CoordinateMapper
end
