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

    def self.get(target, options, build_dir = nil)
      case target
      when /^wasm32-unknown-wasi/
        return(
          RubyWasm::WASISDK.new(
            build_dir: build_dir,
            version: options[:wasi_sdk_version]
          )
        )
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
        @tools_cache ||= {} #: Hash[String, String]
        __skip__ = @tools_cache[name] ||= find_tool(name)
        @tools_cache[name]
      end
    end
  end

  class WASISDK < Toolchain
    def initialize(
      wasi_sdk_path = ENV["WASI_SDK_PATH"],
      build_dir: nil,
      version: "23.0",
      binaryen_version: 108
    )
      @need_fetch_wasi_sdk = wasi_sdk_path.nil?
      if @need_fetch_wasi_sdk
        if build_dir.nil?
          raise "build_dir is required when WASI_SDK_PATH is not set"
        end
        wasi_sdk_path = File.join(build_dir, "toolchain", "wasi-sdk-#{version}")
        if version.nil?
          raise "version is required when WASI_SDK_PATH is not set"
        end
        @version = version
      end

      @binaryen =
        Binaryen.new(build_dir: build_dir, binaryen_version: binaryen_version)

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
      @binaryen.wasm_opt
    end

    def wasi_sdk_path
      @wasi_sdk_path
    end

    def download_url
      major, _ = @version.split(".").map(&:to_i)
      # @type var assets: Array[[Regexp, Array[String]]]
      assets = [
        [
          /x86_64-linux/,
          [
            "wasi-sdk-#{@version}-x86_64-linux.tar.gz",
            # For wasi-sdk version < 23.0
            "wasi-sdk-#{@version}-linux.tar.gz"
          ]
        ],
        [
          /arm64e?-darwin/,
          [
            "wasi-sdk-#{@version}-arm64-macos.tar.gz",
            # For wasi-sdk version < 23.0
            "wasi-sdk-#{@version}-macos.tar.gz"
          ]
        ],
        [
          /x86_64-darwin/,
          [
            "wasi-sdk-#{@version}-x86_64-macos.tar.gz",
            # For wasi-sdk version < 23.0
            "wasi-sdk-#{@version}-macos.tar.gz"
          ]
        ]
      ]
      asset = assets.find { |os, candidates| os =~ RUBY_PLATFORM }
      if asset.nil?
        raise "unsupported platform for fetching WASI SDK: #{RUBY_PLATFORM}"
      end
      _, candidates = asset
      candidates_urls =
        candidates.map do |candidate|
          "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-#{major}/#{candidate}"
        end
      require "net/http"
      # Find an asset that exists by checking HEAD response to see if the asset exists
      candidates_urls.each do |url_str|
        # @type var url: URI::HTTPS
        url = URI.parse(url_str)
        ok =
          __skip__ = Net::HTTP.start(
            url.host,
            url.port,
            use_ssl: url.scheme == "https"
          ) do |http|
            response = http.head(url.request_uri)
            next response.code == "302"
          end
        return url_str if ok
      end
      raise "WASI SDK asset not found: #{candidates_urls.join(", ")}"
    end

    def install_wasi_sdk(executor)
      return unless @need_fetch_wasi_sdk
      wasi_sdk_tarball =
        File.join(File.dirname(@wasi_sdk_path), "wasi-sdk-#{@version}.tar.gz")
      unless File.exist? wasi_sdk_tarball
        FileUtils.mkdir_p File.dirname(wasi_sdk_tarball)
        executor.system "curl",
                        "-fsSL",
                        "-o",
                        wasi_sdk_tarball,
                        self.download_url
      end
      unless File.exist? @wasi_sdk_path
        FileUtils.mkdir_p @wasi_sdk_path
        executor.system "tar",
                        "-C",
                        @wasi_sdk_path,
                        "--strip-component",
                        "1",
                        "-xzf",
                        wasi_sdk_tarball
      end
    end

    def install(executor)
      install_wasi_sdk(executor)
      @binaryen.install(executor)
    end
  end

  class Binaryen
    def initialize(build_dir: nil, binaryen_version: 108)
      @wasm_opt_path = Toolchain.find_path("wasm-opt")
      @need_fetch_binaryen = @wasm_opt_path.nil?
      if @need_fetch_binaryen
        if build_dir.nil?
          raise "build_dir is required when wasm-opt not installed in PATH"
        end
        @binaryen_path = File.join(build_dir, "toolchain", "binaryen")
        @binaryen_version = binaryen_version
        @wasm_opt_path = File.join(@binaryen_path, "bin", "wasm-opt")
      end
    end

    def wasm_opt
      @wasm_opt_path
    end

    def binaryen_path
      @binaryen_path
    end

    def binaryen_version
      @binaryen_version
    end

    def download_url(version)
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

    def install(executor)
      return unless @need_fetch_binaryen
      binaryen_tarball = File.expand_path("../binaryen.tar.gz", @binaryen_path)
      unless File.exist? binaryen_tarball
        FileUtils.mkdir_p File.dirname(binaryen_tarball)
        executor.system "curl",
                        "-L",
                        "-o",
                        binaryen_tarball,
                        self.download_url(@binaryen_version)
      end

      unless File.exist? @binaryen_path
        FileUtils.mkdir_p @binaryen_path
        executor.system "tar",
                        "-C",
                        @binaryen_path,
                        "--strip-component",
                        "1",
                        "-xzf",
                        binaryen_tarball
      end
    end
  end

  class Emscripten < Toolchain
    def initialize
      @tools = {
        cc: "emcc",
        cxx: "em++",
        ld: "emcc",
        ar: "emar",
        ranlib: "emranlib"
      }
      @name = "emscripten"
    end

    def install(executor)
    end

    def find_tool(name)
      Toolchain.check_executable(@tools[name])
      @tools[name]
    end
  end
end
