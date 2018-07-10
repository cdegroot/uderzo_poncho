defmodule Clixir.ElixirBackend do
  @moduledoc """
  Code to emit the Elixir code parts from Clixir
  """

  import Clixir.CodeGenHelpers

  @doc """
  Generate Elixir code to call the C function in the module. The parameter list
  will be marshalled as the binary representation of the erlang term.
  """
  def generate_code(module, function_name, parameter_list) do
    cfun_name = cfun_name(module, function_name) |> String.to_atom
    quote do
      def unquote(function_name)(unquote_splicing(parameter_list)) do
        Clixir.Server.send_command(Clixir.Server, {unquote(cfun_name), unquote_splicing(parameter_list)})
      end
    end
  end
end
