module RubyWasm
  class WitBindgen
    attr_reader :bin_path

    def initialize(
      build_dir:,
      revision: "2e8fb8ede8242288d4cc682cd9dff3057ef09a57"
    )
      @build_dir = build_dir
      @tool_dir = File.join(@build_dir, "toolchain", "wit-bindgen-#{revision}")
      @bin_path = File.join(@tool_dir, "bin", "wit-bindgen")
      @revision = revision
    end

    def install
      return if File.exist?(@bin_path)
      RubyWasm::Toolchain.check_executable("cargo")
      Kernel.system(
        "cargo",
        "install",
        "--git",
        "https://github.com/bytecodealliance/wit-bindgen",
        "--rev",
        @revision,
        "--root",
        @tool_dir,
        "wit-bindgen-cli"
      )
    end
  end
end
