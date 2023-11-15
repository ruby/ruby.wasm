require_relative "build/build_params"
require_relative "build/product"
require_relative "build/toolchain"

module RubyWasm
  # Build executor to run the actual build commands.
  class BuildExecutor
    def initialize(verbose: false)
      @verbose = verbose
    end

    def system(*args, **kwargs)
      puts args.join(" ")
      if @verbose
        out = kwargs[:out] || $stdout
      else
        out = IO.pipe[1]
      end
      Kernel.system(*args, **kwargs, out: out)
    end

    def rm_rf(list)
      FileUtils.rm_rf(list)
    end

    def rm_f(list)
      FileUtils.rm_f(list)
    end

    def cp_r(src, dest)
      FileUtils.cp_r(src, dest)
    end

    def mv(src, dest)
      FileUtils.mv(src, dest)
    end

    def mkdir_p(list)
      FileUtils.mkdir_p(list)
    end

    def write(path, data)
      File.write(path, data)
    end
  end
end
