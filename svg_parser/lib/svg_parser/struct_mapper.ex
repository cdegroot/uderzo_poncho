defmodule SvgParser.StructMapper do
  @moduledoc """
  Map a generic XML parse tree into a structure conforming to
  `SvgParser.Elems`. Currently with little regard for error handling,
  SVG validation, etcetera.
  """

  use SvgParser.Elems

  # Shamelessly stolen from SweetXml to get the pattern matching macros we need.
  require Record
  Record.defrecord :xmlDecl, Record.extract(:xmlDecl, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlNamespace, Record.extract(:xmlNamespace, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlNsNode, Record.extract(:xmlNsNode, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlComment, Record.extract(:xmlComment, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlPI, Record.extract(:xmlPI, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlDocument, Record.extract(:xmlDocument, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlObj, Record.extract(:xmlObj, from_lib: "xmerl/include/xmerl.hrl")

  # xmlerl seems to return {{:xmlElement, ...}, []}
  def map({xmlElement(name: :svg, attributes: attributes, content: content), []}) do
    attr_map = extract_attr_map(attributes)
    elems = content
    |> map()
    |> Enum.filter(fn(e) -> !is_nil(e) end)
    %Svg{height: floatify(attr_map[:height]),
         width: floatify(attr_map[:width]),
         contents: elems}
  end

  def map(elems) when is_list(elems), do: Enum.map(elems, &map/1)

  # We ignore xmlText, that's usually whitespace in the source
  def map(xmlText()), do: nil

  def map(xmlElement(name: :circle, attributes: attributes)) do
    attr_map = extract_attr_map(attributes)
    %Circle{c: pointify(attr_map[:cx], attr_map[:cy]),
            r: scalarify(attr_map[:r]),
            stroke: colourify(attr_map[:stroke]),
            stroke_width: scalarify(attr_map[:"stroke-width"]),
            fill: colourify(attr_map[:fill])}
  end

  defp extract_attr_map(list_of_records) do
    list_of_records
    |> Enum.map(fn xmlAttribute(name: name, value: value) ->
      {name, value}
    end)
    |> Map.new
  end

  defp floatify(value) when is_bitstring(value), do: elem(Float.parse(value), 0)
  defp floatify(value) when is_list(value), do: floatify(to_string(value))

  defp colourify('red'), do: colourify(1, 0, 0)
  defp colourify('black'), do: colourify(0, 0, 0)
  defp colourify(['#', rh, rl, gh, gl, bh, bl]) do
    %Colour{
      r: ((rh * 256) + rl) / 255,
      g: ((gh * 256) + gl) / 255,
      b: ((bh * 256) + bl) / 255,
      a: 0
    }
  end
  defp colourify(r, g, b, a \\ 0), do: %Colour{r: r/1, g: g/1, b: b/1, a: a/1}

  defp scalarify(v), do: %Scalar{l: floatify(v)}

  defp pointify(x, y), do: %Point{x: floatify(x), y: floatify(y)}
end
