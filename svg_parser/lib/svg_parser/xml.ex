defmodule SvgParser.Xml do
  @moduledoc """
  XML parsing and cleanup and (some beautiful day) error handling.
  """

  def parse(xml_string) do
    xml_string
    |> :erlang.binary_to_list()
    |> :xmerl_scan.string([])
  end
end
