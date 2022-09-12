require "rake"
require_relative "./product"

module RubyWasm
  class LibYAMLProduct < AutoconfProduct
    attr_reader :target, :install_task

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
      "libyaml-#{target}"
    end

    def define_task
      desc "build libyaml #{LIBYAML_VERSION} for #{target}"
      @install_task =
        task(name) do
          next if Dir.exist?(install_root)

          mkdir_p File.dirname(product_build_dir)
          rm_rf product_build_dir
          sh "curl -L https://github.com/yaml/libyaml/releases/download/#{LIBYAML_VERSION}/yaml-#{LIBYAML_VERSION}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

          # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
          sh "curl -o #{product_build_dir}/config/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'"
          sh "curl -o #{product_build_dir}/config/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'"

          sh "./configure #{configure_args.join(" ")}", chdir: product_build_dir
          sh "make install DESTDIR=#{destdir}", chdir: product_build_dir
        end
    end
  end
end
