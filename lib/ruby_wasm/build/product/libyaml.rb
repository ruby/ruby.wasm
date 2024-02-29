require_relative "./product"

module RubyWasm
  class LibYAMLProduct < AutoconfProduct
    attr_reader :target

    LIBYAML_VERSION = "0.2.5"

    def initialize(build_dir, target, toolchain)
      @build_dir = build_dir
      @target = target
      super(target, toolchain)
    end

    def product_build_dir
      File.join(@build_dir, target.to_s, "yaml-#{LIBYAML_VERSION}")
    end

    def destdir
      File.join(product_build_dir, "opt")
    end

    def install_root
      File.join(destdir, "usr", "local")
    end

    def name
      "libyaml-#{LIBYAML_VERSION}-#{target}"
    end

    def build(executor)
      return if Dir.exist?(install_root)

      executor.mkdir_p File.dirname(product_build_dir)
      executor.rm_rf product_build_dir
      executor.mkdir_p product_build_dir
      tarball_path =
        File.join(product_build_dir, "libyaml-#{LIBYAML_VERSION}.tar.gz")
      executor.system "curl",
                      "-o",
                      tarball_path,
                      "-L",
                      "https://github.com/yaml/libyaml/releases/download/#{LIBYAML_VERSION}/yaml-#{LIBYAML_VERSION}.tar.gz"
      executor.system "tar",
                      "xzf",
                      tarball_path,
                      "-C",
                      product_build_dir,
                      "--strip-components=1"

      # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
      executor.system "curl",
                      "-o",
                      "#{product_build_dir}/config/config.guess",
                      "https://cdn.jsdelivr.net/gh/gcc-mirror/gcc@master/config.guess"
      executor.system "curl",
                      "-o",
                      "#{product_build_dir}/config/config.sub",
                      "https://cdn.jsdelivr.net/gh/gcc-mirror/gcc@master/config.sub"

      configure_args = self.configure_args.dup
      configure_args << "CFLAGS=-fPIC" if target.pic?
      executor.system "./configure", *configure_args, chdir: product_build_dir
      executor.system "make",
                      "install",
                      "DESTDIR=#{destdir}",
                      chdir: product_build_dir
    end
  end
end
