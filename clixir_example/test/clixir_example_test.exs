defmodule ClixirExampleTest do
  use ExUnit.Case
  doctest ClixirExample

  test "greets the world" do
    assert ClixirExample.hello() == :world
  end
end
