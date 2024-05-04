require_relative "./toolchain/wit_bindgen"

module RubyWasm
  class Toolchain
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
      when /^wasm32-unknown-wasi/
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

    %i[cc cxx ranlib ld ar].each do |name|
      define_method(name) do
        @tools_cache ||= {}
        @tools_cache[name] ||= find_tool(name)
        @tools_cache[name]
      end
    end
  end

  class WASISDK < Toolchain
    def initialize(
      wasi_sdk_path = ENV["WASI_SDK_PATH"],
      build_dir: nil,
      version_major: 20,
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
        cxx: "#{wasi_sdk_path}/bin/clang++",
        ld: "#{wasi_sdk_path}/bin/clang",
        ar: "#{wasi_sdk_path}/bin/llvm-ar",
        ranlib: "#{wasi_sdk_path}/bin/llvm-ranlib"
      }
      @wasi_sdk_path = wasi_sdk_path
      @name = "wasi-sdk"
    end

    def find_tool(name)
      if !File.exist?(@tools[name]) && !ENV["WASI_SDK_PATH"].nil?
        raise "missing tool '#{name}' at #{@tools[name]}"
      end
      @tools[name]
    end

    def wasm_opt
      @wasm_opt_path
    end

    def wasi_sdk_path
      @wasi_sdk_path
    end

    def download_url(version_major, version_minor)
      version = "#{version_major}.#{version_minor}"
      assets = [
        [/x86_64-linux/, "wasi-sdk-#{version}-linux.tar.gz"],
        [/(arm64e?|x86_64)-darwin/, "wasi-sdk-#{version}-macos.tar.gz"]
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
          /arm64e?-darwin/,
          "binaryen-version_#{@binaryen_version}-arm64-macos.tar.gz"
        ]
      ]
      asset = assets.find { |os, _| os =~ RUBY_PLATFORM }&.at(1)
      if asset.nil?
        raise "unsupported platform for fetching Binaryen: #{RUBY_PLATFORM}"
      end
      "https://github.com/WebAssembly/binaryen/releases/download/version_#{@binaryen_version}/#{asset}"
    end

    def install_wasi_sdk
      return unless @need_fetch_wasi_sdk
      wasi_sdk_tarball =
        File.join(File.dirname(@wasi_sdk_path), "wasi-sdk.tar.gz")
      unless File.exist? wasi_sdk_tarball
        FileUtils.mkdir_p File.dirname(wasi_sdk_tarball)
        system "curl -L -o #{wasi_sdk_tarball} #{self.download_url(@version_major, @version_minor)}"
      end
      unless File.exist? @wasi_sdk_path
        FileUtils.mkdir_p @wasi_sdk_path
        system "tar -C #{@wasi_sdk_path} --strip-component 1 -xzf #{wasi_sdk_tarball}"
      end
    end

    def install_binaryen
      return unless @need_fetch_binaryen
      binaryen_tarball = File.expand_path("../binaryen.tar.gz", @binaryen_path)
      unless File.exist? binaryen_tarball
        FileUtils.mkdir_p File.dirname(binaryen_tarball)
        system "curl -L -o #{binaryen_tarball} #{self.binaryen_download_url(@binaryen_version)}"
      end

      unless File.exist? @binaryen_path
        FileUtils.mkdir_p @binaryen_path
        system "tar -C #{@binaryen_path} --strip-component 1 -xzf #{binaryen_tarball}"
      end
    end

    def install
      install_wasi_sdk
      install_binaryen
    end
  end

  class Emscripten < Toolchain
    def initialize
      @tools = { cc: "emcc", cxx: "em++", ld: "emcc", ar: "emar", ranlib: "emranlib" }
      @name = "emscripten"
    end

    def install
    end

    def find_tool(name)
      Toolchain.check_executable(@tools[name])
      @tools[name]
    end
  end
end
