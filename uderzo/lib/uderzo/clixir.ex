defmodule Uderzo.Clixir do
  @moduledoc """
  Code to emit Elixir and C code from a single "clixir" (.cx)
  file.
  """

  defmacro __using__(_opts) do
    quote do
      import Uderzo.Clixir

      Module.register_attribute(__MODULE__, :cfuns, accumulate: true)
      @before_compile Uderzo.Clixir
    end
  end

  defmacro defgfx(clause, do: expression) do
    {function_name, _, parameter_ast} = clause
    parameter_list = Enum.map(parameter_ast, fn({p, _, _}) -> p end)
    {_block, _, exprs} = expression
    c_code = make_c(function_name, parameter_list, exprs)
    e_code = make_e(function_name, parameter_ast, exprs)
    quote do
      @cfuns {unquote(function_name), unquote(c_code)}
      unquote(e_code)
    end
  end

  # TODO only do this when needed (compare timestamps,etc)
  defmacro __before_compile__(env) do
    tmpfile = fn -> "/tmp/clixir-temp-#{node()}-#{:erlang.unique_integer}" end
    target = Module.get_attribute(env.module, :clixir_target)
    if is_nil(target) do
      raise "Please set the @clixir_target attribute on #{env.module}."
    end
    {:ok, header} = File.read(target <> ".hx")
    {:ok, target_file} = File.open(target <> ".c", [:write])
    IO.write(target_file, "#line 1 \"#{target}.hx\"")
    IO.write(target_file, header)
    IO.puts(target_file, "\n\n// END OF HEADER\n\n")
    cfuns = Module.get_attribute(env.module, :cfuns)
    # TODO keep line number information from Elixir code?
    IO.write(target_file, "#line 1 \"#{env.module}\"")
    Enum.map(cfuns, fn {_fun, {hdr, body}} ->
      IO.puts(target_file, hdr)
      IO.puts(target_file, body)
    end)
    gperf_file = tmpfile.() <> ".gperf"
    {:ok, gperf_data} = File.open(gperf_file, [:write])
    IO.write gperf_data, """
    struct dispatch_entry {
      char *name;
      void (*dispatch_func)(const char *buf, unsigned short len, int *index);
    };
    %%
    """
    Enum.map(cfuns, fn {fun, _} -> IO.puts gperf_data, "#{fun}, _dispatch_#{fun}" end)
    File.close(gperf_data)
    # Call gperf and append to generated code
    {result, 0} = System.cmd("gperf", ["-t", gperf_file])
    IO.puts(target_file, result)
    File.rm(gperf_file)
    # Emit dispatch function
    IO.puts target_file, """
    void _dispatch_command(const char *buf, unsigned short len, int *index) {
        char atom[MAXATOMLEN];
        struct dispatch_entry *dpe;
        assert(ei_decode_atom(buf, index, atom) == 0);

        dpe = in_word_set(atom, strlen(atom));
        if (dpe != NULL) {
             (dpe->dispatch_func)(buf, len, index);
        } else {
            fprintf(stderr, "Dispatch function not found for [%s]\\\n", atom);
        }
    }
    """
    File.close(target_file)
  end

  # C code stuff starts here

  def make_c(function_name, parameter_list, exprs) do
    {:ok, iobuf} = StringIO.open("// Generated code for #{function_name} do not edit!")
    cdecls = cdecls(exprs)
    non_decls = non_decls(exprs)
    start_c_fun(iobuf, function_name)
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
  defp start_c_fun(iobuf, function_name) do
    IO.puts(iobuf, "static void _dispatch_#{function_name}(const char *buf, unsigned short len, int *index) {")
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
        "    #{name}[#{name}_len] = '\0';"
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
  def to_c_var(expr) do
    case expr do
      {name, _, nil} -> to_string(name)
      {name, _, context} when is_atom(context) -> "#{to_string(name)}"
      {:&, _, [{name, _, nil}]} -> "&" <> to_string(name)
      {:__aliases__, _, [name]} -> to_string(name)
      number when is_integer(number) or is_float(number) -> to_string(number)
      {oper, _, [lhs, rhs]} -> "#{to_c_var(lhs)} #{to_string(oper)} #{to_c_var(rhs)}"
      constant_string when is_binary(constant_string) ->
        String.replace("\"#{constant_string}\"", "\n", "\\n")
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

  # Elixir code stuff starts here

  def make_e(function_name, parameter_list, _exprs) do
    quote do
      def unquote(function_name)(unquote_splicing(parameter_list)) do
        Uderzo.GraphicsServer.send_command(Uderzo.GraphicsServer, {unquote(function_name), unquote_splicing(parameter_list)})
      end
    end
  end
end
