require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :target

    ZLIB_VERSION = "1.2.13"

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

    def build
      return if Dir.exist?(install_root)

      FileUtils.mkdir_p File.dirname(product_build_dir)
      FileUtils.rm_rf product_build_dir

      system "curl -L https://zlib.net/zlib-#{ZLIB_VERSION}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

      system "#{tools_args.join(" ")} ./configure --static",
             chdir: product_build_dir
      system "make install DESTDIR=#{destdir}", chdir: product_build_dir
    end
  end
end
