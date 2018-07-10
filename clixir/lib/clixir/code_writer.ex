defmodule Clixir.CodeWriter do
  @moduledoc """
  This module does the actual work of `Clixir.__before_compile__/1`. It writes out
  the C and GNU gperf code fragments which later on get combined to form the project's
  `clixir` executable.

  Due to the nature of the system, re-compilation is mostly unavoidable: if we are
  called, then apparently the Elixir compiler decided that the Clixir-using module
  was out of date. We could go all smart and drop a hash over the C code on disk and
  check whether it was changed, but the executables we generate are small so recompilation
  is not a big issue. Therefore, we set things up so that recompilations happens rather
  often instead of trying to avoid it.
  """

  require Logger

  def write_code(module) do
    clixir_dir = Path.join(Mix.Project.build_path(), "clixir")
    :ok = File.mkdir_p(clixir_dir)

    write_c_code(module, clixir_dir)
    write_gperf_code(module, clixir_dir)

  end

  defp write_c_code(module, clixir_dir) do
    target = Path.join(clixir_dir, Atom.to_string(module))
    {:ok, target_file} = File.open(target <> ".c", [:write])

    header_name = Module.get_attribute(module, :clixir_header)
    if is_nil(header_name) do
      Logger.warn("No @clixir_header specified in #{module}")
      ""
    else
      header_file = Path.join("c_src", header_name <> ".hx")
      header = File.read!(header_file)
      IO.write(target_file, "#line 1 \"#{header_file}\"\n")
      IO.write(target_file, header)
    end
    IO.puts(target_file, "\n\n// END OF HEADER\n\n")
    cfuns = Module.get_attribute(module, :cfuns)
    Enum.map(cfuns, fn {_fun, {hdr, body}} ->
      IO.puts(target_file, hdr)
      IO.puts(target_file, body)
    end)
    File.close(target_file)
  end

  defp write_gperf_code(module, clixir_dir) do
    target = Path.join(clixir_dir, Atom.to_string(module))
    {:ok, target_file} = File.open(target <> ".gperf", [:write])

    cfuns = Module.get_attribute(module, :cfuns)
    Enum.map(cfuns, fn {fun, _} -> IO.puts target_file, "#{fun}, _dispatch_#{fun}" end)
    File.close(target_file)
  end
end
