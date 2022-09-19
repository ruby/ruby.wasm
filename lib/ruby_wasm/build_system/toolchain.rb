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

    def self.check_executable(command)
      (ENV["PATH"] || "")
        .split(File::PATH_SEPARATOR)
        .each do |path_dir|
          bin_path = File.join(path_dir, command)
          return bin_path if File.executable?(bin_path)
        end
      raise "missing executable: #{command}"
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
      version_minor: 0
    )
      if wasi_sdk_path.nil?
        if build_dir.nil?
          raise "build_dir is required when WASI_SDK_PATH is not set"
        end
        wasi_sdk_path = File.join(build_dir, "toolchain", "wasi-sdk")
        @need_fetch = true
        @version_major = version_major
        @version_minor = version_minor
      else
        @need_fetch = false
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

    def define_task
      @task ||= fetch_task(@wasi_sdk_path)
    end

    def install_task
      @task
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

    def fetch_task(output_dir)
      unless @need_fetch
        return task "wasi-sdk:fetch" => [] do
        end
      end
      tarball = File.join(File.dirname(output_dir), "wasi-sdk.tar.gz")
      file tarball do
        mkdir_p output_dir
        sh "curl -L -o #{tarball} #{self.download_url(@version_major, @version_minor)}"
      end
      task "wasi-sdk:fetch" => tarball do
        sh "tar -C #{output_dir} --strip-component 1 -xzf #{tarball}"
      end
    end
  end

  class Emscripten < Toolchain
    def initialize
      @tools = { cc: "emcc", ld: "emcc", ar: "emar", ranlib: "emranlib" }
      @name = "emscripten"
    end

    def define_task
    end
    def install_task
    end

    def find_tool(name)
      Toolchain.check_executable(@tools[name])
      @tools[name]
    end
  end
end
