require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :target

    ZLIB_VERSION = "1.3"

    def initialize(build_dir, target, toolchain)
      @build_dir = build_dir
      @target = target
      super(target, toolchain)
    end

    def product_build_dir
      File.join(@build_dir, target, "zlib-#{ZLIB_VERSION}")
    end

    def destdir
      File.join(product_build_dir, "opt")
    end

    def install_root
      File.join(destdir, "usr", "local")
    end

    def name
      product_build_dir
    end

    def configure_args
      args = %w[CHOST=linux]

      args + tools_args
    end

    def build(executor)
      return if Dir.exist?(install_root)

      executor.mkdir_p File.dirname(product_build_dir)
      executor.rm_rf product_build_dir

      executor.system "curl -L https://zlib.net/zlib-#{ZLIB_VERSION}.tar.gz | tar xz",
                      chdir: File.dirname(product_build_dir)

      executor.system "#{configure_args.join(" ")} ./configure --static",
                      chdir: product_build_dir
      executor.system "make install DESTDIR=#{destdir}",
                      chdir: product_build_dir
    end
  end
end
