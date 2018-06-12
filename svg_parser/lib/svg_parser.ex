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

end
