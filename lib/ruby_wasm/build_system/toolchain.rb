module RubyWasm
  class Toolchain
    def initialize
    end

    [:cc, :ranlib, :ld, :ar].each do |name|
      attr_reader name
    end
  end

  class WASISDK < Toolchain
    def initialize(wasi_sdk_path = ENV["WASI_SDK_PATH"])
      @cc = "#{wasi_sdk_path}/bin/clang"
      @ranlib = "#{wasi_sdk_path}/bin/llvm-ranlib"
      @ld = "#{wasi_sdk_path}/bin/clang"
      @ar = "#{wasi_sdk_path}/bin/llvm-ar"
    end
  end

  class Emscripten < Toolchain
    def initialize
      @cc = "emcc"
      @ranlib = "emranlib"
      @ld = "emcc"
      @ar = "emar"
    end
  end

end