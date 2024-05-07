module RubyWasm
  class WitBindgen
    attr_reader :bin_path

    def initialize(
      build_dir:,
      revision: "67e17745a417d07852cc283d1399d210d4d659cc"
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
