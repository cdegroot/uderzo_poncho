defmodule Clixir do
  @moduledoc """
  Code to emit Elixir and C code from a single "clixir" (.cx)
  file.

  Pull this in through a `use Clixir` statement.
  """

  defmacro __using__(_opts) do
    quote do
      import Clixir

      Module.register_attribute(__MODULE__, :cfuns, accumulate: true)
      @before_compile Clixir
    end
  end

  @doc """
  Define a C function. The function body will be translated into C. The function definition
  will be available in Elixir and can be called like any other function. The process is largely
  transparent except for the somewhat arbitrary shortcomings of the C backend.

  The elixir code is inserted directly in the module. The C code is added to a special
  attribute that a `__before_compile__` macro reads for further processing.
  """
  defmacro def_c(clause, do: expression) do
    {function_name, _, parameter_ast} = clause
    parameter_list = Enum.map(parameter_ast, fn({p, _, _}) -> p end)
    {_block, _, exprs} = expression
    module = __CALLER__.module
    location = {__CALLER__.file, __CALLER__.line}
    c_code = Clixir.CBackend.generate_code(module, function_name, parameter_list, exprs, location)
    e_code = Clixir.ElixirBackend.generate_code(module, function_name, parameter_ast)
    cfun_name = Clixir.CodeGenHelpers.cfun_name(module, function_name)
    quote do
      @cfuns {unquote(cfun_name), unquote(c_code)}
      unquote(e_code)
    end
  end

  defmacro __before_compile__(env) do
    Clixir.CodeWriter.write_code(env.module)
  end
end
