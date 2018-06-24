defmodule Clixir.CodeGenHelpers do
  @moduledoc """
  Code that is used by both the C and Elixir backends.
  """

  @doc """
  Make a C function name from the module name and the function name. This
  basically just smacks them together to make them globally unique.
  """
  def cfun_name(module, function_name) do
    module_s = module
    |> Atom.to_string()
    |> String.replace(".", "_")
    function_s = function_name
    |> Atom.to_string()
    Enum.join([module_s, function_s], "_")
  end

end
