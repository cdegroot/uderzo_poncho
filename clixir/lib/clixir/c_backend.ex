defmodule Clixir.CBackend do
  @moduledoc """
  Code to emit the C code parts from Clixir

  Note that this code currently is very ad hoc and supports a very small
  subset of C. It has - hopefully - helpful error messages for when it
  does not understand C so it should be easy to add things. However, it
  really needs some cleanup to be less ad hoc and more like what you
  learn in compiler writing class ;-)
  """

  import Clixir.CodeGenHelpers

  def generate_code(module, function_name, parameter_list, exprs, {file, line}) do
    {:ok, iobuf} = StringIO.open("// Generated code for #{function_name} from #{Atom.to_string(module)}\n")
    cdecls = cdecls(exprs)
    non_decls = non_decls(exprs)
    IO.write(iobuf, "#line #{line} \"#{file}\"\n")
    start_c_fun(iobuf, module, function_name)
    emit_c_local_vars(iobuf, cdecls)
    emit_c_unmarshalling(iobuf, parameter_list, cdecls)
    emit_c_body(iobuf, cdecls, non_decls)
    end_c_fun(iobuf)
    StringIO.contents(iobuf)
  end

  defp cdecls(exprs) do
    # Return c declarations as %{name -> type} map
    exprs
    |> Enum.flat_map(fn
      {:cdecl, _, [[{ctype, {cname, _, _}}]]} ->
        [{cname, ctype}]
      {:cdecl, _, [[{ctype, cnames}]]} ->
        Enum.map(cnames, fn({cname, _, _}) -> {cname, ctype} end)
      _ -> []
    end)
    |> Enum.filter(fn e -> !is_nil(e) end)
    |> Map.new
  end
  defp non_decls(exprs) do
    exprs
    |> Enum.filter(fn maybe_decl -> elem(maybe_decl, 0) != :cdecl end)
  end
  defp start_c_fun(iobuf, module, function_name) do
    IO.puts(iobuf, "static void _dispatch_#{cfun_name(module, function_name)}(const char *buf, unsigned short len, int *index) {")
  end
  defp emit_c_local_vars(iobuf, cdecls) do
    cdecls
    |> Enum.map(fn
      ({decl, :"char *"}) -> IO.puts(iobuf, "    char #{decl}[BUF_SIZE];")
                            IO.puts(iobuf, "    long #{decl}_len;")
      ({decl, type}) ->     IO.puts(iobuf, "    #{to_string type} #{decl};")
    end)
  end
  defp emit_c_unmarshalling(iobuf, parameter_list, cdecls) do
    parameter_list
    |> Enum.map(fn(p) -> {p, cdecls[p]} end)
    |> Enum.map(fn
      # Fairly manual list, we can clean this up later when we have a better overview of regularities
      {name, :double} ->
        "    assert(ei_decode_double(buf, index, &#{name}) == 0);"
      {name, :long} ->
        "    assert(ei_decode_long(buf, index, &#{name}) == 0);"
      {name, :"char *"} ->
        "    assert(ei_decode_binary(buf, index, #{name}, &#{name}_len) == 0);\n" <>
        "    #{name}[#{name}_len] = '\\0';"
      {name, :erlang_pid} ->
        "    assert(ei_decode_pid(buf, index, &#{name}) == 0);"
      {name, type} ->
        if String.ends_with?(to_string(type), "*") do
          "    assert(ei_decode_longlong(buf, index, (long long *) &#{name}) == 0);"
        else
          raise "unknown type #{type} for variable #{name}, please fix macro"
        end
    end)
    |> Enum.map(&(IO.puts(iobuf, &1)))
  end

  # Ok, the following couple of functions are currently horribly named. Also, this
  # is not really clean - got incrementally built when working on Clixir's spec and
  # first implementation.
  # What really needs to happen is: TODO:
  # a) transform Elixir AST into C AST
  # b) emit C code for C AST
  @indent "    "
  defp emit_c_body(iobuf, cdecls, exprs, indent \\ @indent)
  defp emit_c_body(iobuf, cdecls, {:__block__, _, exprs}, indent) do
    emit_c_body(iobuf, cdecls, exprs, indent)
  end
  defp emit_c_body(iobuf, cdecls, exprs, indent) when is_list(exprs) do
    Enum.map(exprs, &(emit_c_body(iobuf, cdecls, &1, indent)))
  end
  defp emit_c_body(iobuf, cdecls, expr, indent) do
    case expr do
      {:=, _, [{left, _, _}, right]} ->
        # Assignment
        IO.write(iobuf, "#{indent}#{left} = ")
        emit_c_body(iobuf, cdecls, [right], "")
      {:if, _, if_stmt} ->
        emit_c_if(iobuf, cdecls, if_stmt, indent)
      {binary_op, _, args} when binary_op in [:+, :-, :/, :*] ->
        # Note that the list above is incomplete. Add as needed.
        [lhs, rhs] = args
        |> Enum.map(&to_c_var/1)
        IO.puts(iobuf, "#{indent}#{lhs} #{to_string binary_op} #{rhs};")
      {var, _, nil} when is_atom(var) ->
        # Variable reference, e.g. in assignment
        IO.write(iobuf, "#{var};")
      {funcall, _, args} ->
        # Function call
        cargs = args
        |> Enum.map(&to_c_var/1)
        |> Enum.join(", ")
        IO.puts(iobuf, "#{indent}#{funcall}(#{cargs});")
      # Return tuple. This is probably more hardcoded than we need. Better safe than sorry
      # We _always_ return {pid, {return_tuple}}. We need multiple clauses as Elixir handles
      # 2-tuples in a special way.
      {{:pid, _, _}, {:{}, _, return_values}} ->
        retvals = return_values
        |> Enum.map(fn
          {name, _, _} -> name
          atom         -> {:atom, atom}
        end)
        emit_marshal_return_values(iobuf, retvals, cdecls, indent)
      {{:pid, _, _}, return_values} when is_tuple(return_values) ->
        retvals = return_values
        |> Tuple.to_list
        |> Enum.map(fn
          {name, _, _} -> name
          atom         -> {:atom, atom}
        end)
        emit_marshal_return_values(iobuf, retvals, cdecls, indent)
      {{:pid, _, _}, return_value} ->
        retval = case return_value do
          {name, _, _} -> name
          atom         -> {:atom, atom}
        end
        emit_marshal_return_values(iobuf, [retval], cdecls, indent)
      expr -> raise "unknown expr #{inspect expr}, please fix macro or defgfx declaration"
    end
  end
  defp to_c_var(expr) do
    case expr do
      {name, _, nil} -> to_string(name)
      {name, _, context} when is_atom(context) -> "#{to_string(name)}"
      {:&, _, [{name, _, nil}]} -> "&" <> to_string(name)
      {:__aliases__, _, [name]} -> to_string(name)
      number when is_integer(number) or is_float(number) -> to_string(number)
      {oper, _, [lhs, rhs]} -> "#{to_c_var(lhs)} #{to_string(oper)} #{to_c_var(rhs)}"
      constant_string when is_binary(constant_string) ->
        "\"#{constant_string}\"" |> String.replace("\n", "\\n")
      {{:., _, [{var, _, nil}, struct_elem]}, _, []} -> "#{var}.#{struct_elem}"
      {funcall, _, args} ->
        cargs = args
        |> Enum.map(&to_c_var/1)
        |> Enum.join(", ")
        "#{funcall}(#{cargs})"
      other_pattern -> raise "unknown C AST form #{inspect other_pattern}, please fix macro"
    end
  end
  # For now, only single-operator if statements are handled.
  defp emit_c_if(iobuf, cdecls, [conditional, [do: if_true_exprs]], indent) do
    IO.puts(iobuf, "#{indent}if (#{to_c_var(conditional)}) {")
    emit_c_body(iobuf, cdecls, if_true_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}}")
  end
  defp emit_c_if(iobuf, cdecls, [conditional, [do: if_true_exprs, else: if_false_exprs]], indent) do
    IO.puts(iobuf, "#{indent}if (#{to_c_var(conditional)}) {")
    emit_c_body(iobuf, cdecls, if_true_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}} else {")
    emit_c_body(iobuf, cdecls, if_false_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}}")
  end
  defp emit_marshal_return_values(iobuf, retvals, cdecls, indent) do
    IO.write(iobuf, """
      #{indent}char response[BUF_SIZE];
      #{indent}int response_index = 0;
      #{indent}ei_encode_version(response, &response_index);
      #{indent}ei_encode_tuple_header(response, &response_index, 2);
      #{indent}ei_encode_pid(response, &response_index, &pid);
      """)
    if length(retvals) > 1 do
      IO.puts(iobuf, "#{indent}ei_encode_tuple_header(response, &response_index, #{length(retvals)});")
    end
    retvals
    |> Enum.map(fn(retval) ->
      type = cdecls[retval]
      case {retval, type} do
        {{:atom, atom}, nil} when is_binary(atom) ->
          IO.puts(iobuf, "#{indent}ei_encode_string(response, &response_index, \"#{atom}\");")
        {{:atom, atom}, nil} when is_integer(atom) ->
          IO.puts(iobuf, "#{indent}ei_encode_longlong(response, &response_index, #{atom});")
        {{:atom, atom}, nil} when is_float(atom) ->
          IO.puts(iobuf, "#{indent}ei_encode_double(response, &response_index, #{atom});")
        {{:atom, atom}, nil} ->
          IO.puts(iobuf, "#{indent}ei_encode_atom(response, &response_index, \"#{to_string atom}\");")
        {name, :double} ->
          IO.puts(iobuf, "#{indent}ei_encode_double(response, &response_index, #{name});")
        {name, integer} when integer in [:int, :long] ->
          IO.puts(iobuf, "#{indent}ei_encode_long(response, &response_index, #{name});")
        {name, type} ->
          if String.ends_with?(to_string(type), "*") do
            IO.puts(iobuf, "#{indent}ei_encode_longlong(response, &response_index, (long long) #{name});")
          else
            raise("unknown type in return #{inspect name}: #{inspect type}, please fix macro")
          end
      end
    end)
    IO.puts(iobuf, "#{indent}write_response_bytes(response, response_index);")
  end
  defp end_c_fun(iobuf) do
    IO.puts(iobuf, "}")
  end

end
