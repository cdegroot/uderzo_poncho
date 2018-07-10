defmodule Mix.Tasks.Compile.Clixir do
  @moduledoc """
  This tasks collects all the fragments that the Clixir macro invocations
  have generated, and does the finishing job. You need to add this compiler
  to the Mix configuration of your project, typically as a step between the
  regular compilation and elixir_make:

      def project() do
        app: myapp,
        compilers: Mix.compilers ++ [:clixir, :elixir_make]
      end

  The source is generated in c_src/<<application>>.c and will be overwritten!
  """

  require Logger

  def run(_args) do
    clixir_dir = Path.join(Mix.Project.build_path(), "clixir")
    if File.exists?(clixir_dir) do
      generate_code(clixir_dir)
    else
      Logger.warn("No Clixir files found in #{clixir_dir}, skipping final code generation step")
      :noop
    end
  end

  defp generate_code(clixir_dir) do
    File.mkdir("c_src")
    app_name = Mix.Project.config
    |> Keyword.get(:app)
    |> Atom.to_string()
    output_file_name = Path.join("c_src", app_name <> ".c")
    output_file = File.open!(output_file_name, [:write])

    IO.puts(output_file, "#include <clixir_support.h>")

    for c_code_file <- Path.wildcard(clixir_dir <> "/*.c") do
      code = File.read!(c_code_file)
      IO.write(output_file, code)
      IO.write(output_file, "\n")
    end

    build_gperf_fun(clixir_dir, output_file)
    build_dispatch_fun(output_file)

    File.close(output_file)

    :ok
  end

  defp build_gperf_fun(clixir_dir, output_file) do
    gperf_filename = tmpfile() <> ".gperf"
    gperf_file = File.open!(gperf_filename, [:write])

    IO.write gperf_file, """
    struct dispatch_entry {
      char *name;
      void (*dispatch_func)(const char *buf, unsigned short len, int *index);
    };
    %%
    """
    for gperf_part <- Path.wildcard(clixir_dir <> "/*.gperf") do
      code = File.read!(gperf_part)
      IO.write(gperf_file, code)
    end
    File.close(gperf_file)

    {result, 0} = System.cmd("gperf", ["-t", gperf_filename])
    IO.puts(output_file, result)
    File.rm(gperf_filename)
  end

  defp build_dispatch_fun(output_file) do
    IO.puts output_file,  """
    void _dispatch_command(const char *buf, unsigned short len, int *index) {
        char atom[MAXATOMLEN];
        struct dispatch_entry *dpe;
        assert(ei_decode_atom(buf, index, atom) == 0);

        dpe = in_word_set(atom, strlen(atom));
        if (dpe != NULL) {
             (dpe->dispatch_func)(buf, len, index);
        } else {
            fprintf(stderr, "Dispatch function not found for [%s]\\n", atom);
        }
    }
    """
  end

  defp tmpfile, do: "/tmp/clixir-temp-#{node()}-#{:erlang.unique_integer}"
end
