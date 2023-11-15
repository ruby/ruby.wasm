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
      File.join(@build_dir, target, "yaml-#{LIBYAML_VERSION}")
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
      system "curl -L https://github.com/yaml/libyaml/releases/download/#{LIBYAML_VERSION}/yaml-#{LIBYAML_VERSION}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

      # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
      system "curl -o #{product_build_dir}/config/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'"
      system "curl -o #{product_build_dir}/config/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'"

      system "./configure #{configure_args.join(" ")}", chdir: product_build_dir
      system "make install DESTDIR=#{destdir}", chdir: product_build_dir
    end
  end
end
