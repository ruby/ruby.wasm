module RubyWasm
  class WitBindgen < ::Rake::TaskLib
    attr_reader :bin_path

    def initialize(
      build_dir:,
      revision: "251e84b89121751f79ac268629e9285082b2596d"
    )
      @build_dir = build_dir
      @tool_dir = File.join(@build_dir, "toolchain", "wit-bindgen")
      @bin_path = File.join(@tool_dir, "bin", "wit-bindgen")
      @revision = revision
    end

    def install
      return if File.exist?(@bin_path)
      RubyWasm::Toolchain.check_executable("cargo")
      system *[
               "cargo",
               "install",
               "--git",
               "https://github.com/bytecodealliance/wit-bindgen",
               "--rev",
               @revision,
               "--root",
               @tool_dir,
               "wit-bindgen-cli"
             ]
    end
  end
end
