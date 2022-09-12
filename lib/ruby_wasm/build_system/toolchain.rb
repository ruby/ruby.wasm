module RubyWasm
  class Toolchain
    def initialize
      @tools = {}
    end

    def find_tool(name)
      raise "not implemented"
    end

    def check_envvar(name)
      raise "missing environment variable: #{name}" if ENV[name].nil?
    end

    def self.get(target)
      case target
      when "wasm32-unknown-wasi"
        return RubyWasm::WASISDK.new
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
    def initialize(wasi_sdk_path = ENV["WASI_SDK_PATH"])
      @tools = {
        cc: "#{wasi_sdk_path}/bin/clang",
        ld: "#{wasi_sdk_path}/bin/clang",
        ar: "#{wasi_sdk_path}/bin/llvm-ar",
        ranlib: "#{wasi_sdk_path}/bin/llvm-ranlib"
      }
    end

    def lib_wasi_vfs_a
      archive = ENV["LIB_WASI_VFS_A"]
      if archive.nil?
        STDERR.puts "warning: vfs feature is not enabled due to no LIB_WASI_VFS_A"
      end
      archive
    end

    def find_tool(name)
      unless File.exist? @tools[name]
        check_envvar("WASI_SDK_PATH")
        raise "missing tool '#{name}' at #{@tools[name]}"
      end
      @tools[name]
    end
  end

  class Emscripten < Toolchain
    def initialize
      @tools = { cc: "emcc", ld: "emcc", ar: "emar", ranlib: "emranlib" }
    end

    def find_tool(name)
      Toolchain.check_executable(@tools[name])
      @tools[name]
    end
  end
end
