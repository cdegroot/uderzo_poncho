defmodule Clixir.CodeWriter do
  @moduledoc """
  This module does the actual work of `Clixir.__before_compile__/1`. It writes out
  the C and GNU gperf code fragments which later on get combined to form the project's
  `clixir` executable.
  """

  require Logger

  # TODO only do this when needed (compare timestamps,etc)
  #   (this is quite hairy so probably wants to dig into Elixir's dependency management)
  def write_code(module) do
    clixir_dir = Path.join(Mix.Project.build_path(), "clixir")
    :ok = File.mkdir_p(clixir_dir)

    # Write C file
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

    # Dump data for gperf
    {:ok, target_file} = File.open(target <> ".gperf", [:write])
    Enum.map(cfuns, fn {fun, _} -> IO.puts target_file, "#{fun}, _dispatch_#{fun}" end)
    File.close(target_file)
  end
end
