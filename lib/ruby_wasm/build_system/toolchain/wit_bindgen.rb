module RubyWasm
  class WitBindgen < ::Rake::TaskLib
    attr_reader :bin_path

    def initialize(build_dir:, revision: "bb33644b4fd21ecf43761f63c472cdfffe57e300")
      @build_dir = build_dir
      @tool_dir = File.join(@build_dir, "toolchain", "wit-bindgen")
      @bin_path = File.join(@tool_dir, "bin", "wit-bindgen")
      @revision = revision
    end

    def define_task
      file @bin_path do
        RubyWasm::Toolchain.check_executable("cargo")
        sh *[
          "cargo", "install",
          "--git", "https://github.com/bytecodealliance/wit-bindgen",
          "--rev", @revision, "--root", @tool_dir,
          "wit-bindgen-cli",
        ]
      end
      @task ||= task "wit-bindgen:install" => @bin_path
    end

    def install_task
      @task
    end
  end
end