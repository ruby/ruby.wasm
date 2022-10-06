require_relative "./toolchain/wit_bindgen"

module RubyWasm
  class Toolchain < ::Rake::TaskLib
    attr_reader :name

    def initialize
      @tools = {}
    end

    def find_tool(name)
      raise "not implemented"
    end

    def check_envvar(name)
      raise "missing environment variable: #{name}" if ENV[name].nil?
    end

    def self.get(target, build_dir = nil)
      case target
      when "wasm32-unknown-wasi"
        return RubyWasm::WASISDK.new(build_dir: build_dir)
      when "wasm32-unknown-emscripten"
        return RubyWasm::Emscripten.new
      else
        raise "unknown target: #{target}"
      end
    end

    def self.find_path(command)
      (ENV["PATH"] || "")
        .split(File::PATH_SEPARATOR)
        .each do |path_dir|
          bin_path = File.join(path_dir, command)
          return bin_path if File.executable?(bin_path)
        end
      nil
    end

    def self.check_executable(command)
      tool = find_path(command)
      raise "missing executable: #{command}" unless tool
      tool
    end

    %i[cc ranlib ld ar].each do |name|
      define_method(name) do
        @tools[name] ||= find_tool(name)
        @tools[name]
      end
    end
  end

  class WASISDK < Toolchain
    def initialize(
      wasi_sdk_path = ENV["WASI_SDK_PATH"],
      build_dir: nil,
      version_major: 14,
      version_minor: 0,
      binaryen_version: 108
    )
      @wasm_opt_path = Toolchain.find_path("wasm-opt")
      @need_fetch_wasi_sdk = wasi_sdk_path.nil?
      @need_fetch_binaryen = @wasm_opt_path.nil?

      if @need_fetch_wasi_sdk
        if build_dir.nil?
          raise "build_dir is required when WASI_SDK_PATH is not set"
        end
        wasi_sdk_path = File.join(build_dir, "toolchain", "wasi-sdk")
        @version_major = version_major
        @version_minor = version_minor
      end

      if @need_fetch_binaryen
        if build_dir.nil?
          raise "build_dir is required when wasm-opt not installed in PATH"
        end
        @binaryen_path = File.join(build_dir, "toolchain", "binaryen")
        @binaryen_version = binaryen_version
        @wasm_opt_path = File.join(@binaryen_path, "bin", "wasm-opt")
      end

      @tools = {
        cc: "#{wasi_sdk_path}/bin/clang",
        ld: "#{wasi_sdk_path}/bin/clang",
        ar: "#{wasi_sdk_path}/bin/llvm-ar",
        ranlib: "#{wasi_sdk_path}/bin/llvm-ranlib"
      }
      @wasi_sdk_path = wasi_sdk_path
      @name = "wasi-sdk"
    end

    def find_tool(name)
      unless File.exist? @tools[name]
        check_envvar("WASI_SDK_PATH")
        raise "missing tool '#{name}' at #{@tools[name]}"
      end
      @tools[name]
    end

    def wasm_opt
      @wasm_opt_path
    end

    def define_task
      @task ||= fetch_task
    end

    def install_task
      @task
    end

    def binaryen_install_task
      @binaryen_install_task
    end

    def download_url(version_major, version_minor)
      version = "#{version_major}.#{version_minor}"
      assets = [
        [/x86_64-linux/, "wasi-sdk-#{version}-linux.tar.gz"],
        [/(arm64|x86_64)-darwin/, "wasi-sdk-#{version}-macos.tar.gz"]
      ]
      asset = assets.find { |os, _| os =~ RUBY_PLATFORM }&.at(1)
      if asset.nil?
        raise "unsupported platform for fetching WASI SDK: #{RUBY_PLATFORM}"
      end
      "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-#{version_major}/#{asset}"
    end

    def binaryen_download_url(version)
      assets = [
        [
          /x86_64-linux/,
          "binaryen-version_#{@binaryen_version}-x86_64-linux.tar.gz"
        ],
        [
          /x86_64-darwin/,
          "binaryen-version_#{@binaryen_version}-x86_64-macos.tar.gz"
        ],
        [
          /arm64-darwin/,
          "binaryen-version_#{@binaryen_version}-arm64-macos.tar.gz"
        ]
      ]
      asset = assets.find { |os, _| os =~ RUBY_PLATFORM }&.at(1)
      if asset.nil?
        raise "unsupported platform for fetching Binaryen: #{RUBY_PLATFORM}"
      end
      "https://github.com/WebAssembly/binaryen/releases/download/version_#{@binaryen_version}/#{asset}"
    end

    def fetch_task
      required = []
      if @need_fetch_wasi_sdk
        wasi_sdk_tarball =
          File.join(File.dirname(@wasi_sdk_path), "wasi-sdk.tar.gz")
        file wasi_sdk_tarball do
          mkdir_p File.dirname(wasi_sdk_tarball)
          sh "curl -L -o #{wasi_sdk_tarball} #{self.download_url(@version_major, @version_minor)}"
        end
        wasi_sdk =
          file_create @wasi_sdk_path => wasi_sdk_tarball do
            mkdir_p @wasi_sdk_path
            sh "tar -C #{@wasi_sdk_path} --strip-component 1 -xzf #{wasi_sdk_tarball}"
          end
        required << wasi_sdk
      end

      if @need_fetch_binaryen
        binaryen_tarball =
          File.expand_path("../binaryen.tar.gz", @binaryen_path)
        file binaryen_tarball do
          mkdir_p File.dirname(binaryen_tarball)
          sh "curl -L -o #{binaryen_tarball} #{self.binaryen_download_url(@binaryen_version)}"
        end

        binaryen =
          file_create @binaryen_path => binaryen_tarball do
            mkdir_p @binaryen_path
            sh "tar -C #{@binaryen_path} --strip-component 1 -xzf #{binaryen_tarball}"
          end
        @binaryen_install_task ||= task "binaryen:install" => [binaryen]
        required << binaryen
      else
        # no-op when already available
        @binaryen_install_task ||= task "binaryen:install"
      end
      multitask "wasi-sdk:install" => required
    end
  end

  class Emscripten < Toolchain
    def initialize
      @tools = { cc: "emcc", ld: "emcc", ar: "emar", ranlib: "emranlib" }
      @name = "emscripten"
    end

    def define_task
      @task ||= task "emscripten:install"
    end

    def install_task
      @task
    end

    def find_tool(name)
      Toolchain.check_executable(@tools[name])
      @tools[name]
    end
  end
end
