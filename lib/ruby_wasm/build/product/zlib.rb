require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :target

    ZLIB_VERSION = "1.3.1"

    def initialize(build_dir, target, toolchain)
      @build_dir = build_dir
      @target = target
      super(target, toolchain)
    end

    def product_build_dir
      File.join(@build_dir, target.to_s, "zlib-#{ZLIB_VERSION}")
    end

    def destdir
      File.join(product_build_dir, "opt")
    end

    def install_root
      File.join(destdir, "usr", "local")
    end

    def name
      "zlib-#{ZLIB_VERSION}-#{target}"
    end

    def configure_args
      args = %w[CHOST=linux]

      args + tools_args
    end

    def build(executor)
      return if Dir.exist?(install_root)

      executor.mkdir_p File.dirname(product_build_dir)
      executor.rm_rf product_build_dir
      executor.mkdir_p product_build_dir

      tarball_path = File.join(product_build_dir, "zlib-#{ZLIB_VERSION}.tar.gz")
      executor.system "curl",
                      "-o",
                      tarball_path,
                      "-L",
                      "https://github.com/madler/zlib/releases/download/v#{ZLIB_VERSION}/zlib-#{ZLIB_VERSION}.tar.gz"
      executor.system "tar",
                      "xzf",
                      tarball_path,
                      "-C",
                      product_build_dir,
                      "--strip-components=1"

      configure_args = self.configure_args.dup
      configure_args << "CFLAGS=-fPIC" if target.pic?
      executor.system "env",
                      *configure_args,
                      "./configure",
                      "--static",
                      chdir: product_build_dir
      executor.system "make",
                      "install",
                      "DESTDIR=#{destdir}",
                      chdir: product_build_dir
    end
  end
end
