defmodule SvgParser.CoordinateMapper do
  @moduledoc """
  This module helps in mapping SVG coordinates between systems, scaling,
  etcetera. At some point, this'll end up just applying a 2D transform,
  but KISS for now, we do rotations later.
  """
  use SvgParser.Elems


  def normalize(%Svg{height: h, width: w} = svg) do
    scale(svg, 1 / h, 1 / w)
  end

  def scale(svg, xs, ys) do
    transform(svg, xs, ys, 0, 0)
  end
  def move(svg, x, y) do
    transform(svg, 1.0, 1.0, x, y)
  end

  def transform(%Svg{height: h, width: w, contents: contents}, xs, ys, x, y) do
    transformed_contents = contents
    |> Enum.map(fn item -> transform_item(item, xs, ys, x, y) end)
    %Svg{height: h * xs, width: w * ys, contents: transformed_contents}
  end

  defp transform_item(elem, xs, ys, x, y) do
    tag = Map.get(elem, :__struct__)
    elem
    |> Map.from_struct()
    |> Enum.map(&(transform_attribute(&1, xs, ys, x, y)))
    |> Map.new()
    |> Map.put(:__struct__, tag)
  end

  defp transform_attribute({k, %Point{x: px, y: py}}, xs, ys, x, y) do
    {k, %Point{x: (px * xs) + x, y: (py * ys) + y}}
  end

  defp transform_attribute({k, %Scalar{l: l}}, xs, ys, _x, _y) do
    # Hmm... now what? We'll figure out the exact math later on ;-)
    avg_ratio = (xs + ys) / 2
    {k, %Scalar{l: l * avg_ratio}}
  end

  defp transform_attribute(kv, _xs, _ys, _x, _y), do: kv
end
