require "rake"
require_relative "./product"

module RubyWasm
  class LibYAMLProduct < AutoconfProduct
    attr_reader :base_dir, :install_dir, :target, :install_task

    def initialize(build_dir, install_dir, target, toolchain)
      @build_dir = build_dir
      @install_dir = install_dir
      @target = target
      super(target, toolchain)
    end

    def install_root
      File.join(install_dir, "usr/local")
    end

    def name
      "libyaml-#{target}"
    end

    def define_task
      libyaml_version = "0.2.5"
      desc "build libyaml #{libyaml_version} for #{target}"
      @install_task =
        task(name) do
          next if Dir.exist?(install_root)

          product_build_dir =
            File.join(@build_dir, target, "yaml-#{libyaml_version}")
          mkdir_p File.dirname(product_build_dir)
          rm_rf product_build_dir
          sh "curl -L https://github.com/yaml/libyaml/releases/download/#{libyaml_version}/yaml-#{libyaml_version}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

          # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
          sh "curl -o #{product_build_dir}/config/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'"
          sh "curl -o #{product_build_dir}/config/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'"

          sh "./configure #{configure_args.join(" ")}", chdir: product_build_dir
          sh "make install DESTDIR=#{install_dir}", chdir: product_build_dir
        end
    end
  end
end