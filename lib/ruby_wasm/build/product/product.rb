module RubyWasm
  class BuildProduct
    def name
      raise NotImplementedError, "identifiable product name must be implemented"
    end
  end

  class AutoconfProduct < BuildProduct
    def initialize(target, toolchain)
      @target = target
      @toolchain = toolchain
    end
    def system_triplet_args
      args = []
      case @target.triple
      when /^wasm32-unknown-wasi/
        args.concat(%W[--host wasm32-wasi])
      when "wasm32-unknown-emscripten"
        args.concat(%W[--host wasm32-emscripten])
      else
        raise "unknown target: #{@target.triple}"
      end
      args
    end

    def tools_args
      args = []
      args << "CC=#{@toolchain.cc}"
      args << "LD=#{@toolchain.ld}"
      args << "AR=#{@toolchain.ar}"
      args << "RANLIB=#{@toolchain.ranlib}"
      args
    end

    def configure_args
      system_triplet_args + tools_args
    end
  end
end
