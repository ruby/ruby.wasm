require "rake"
require_relative "./product"

module RubyWasm
  class LibYAMLTask < BuildProduct
    attr_reader :base_dir, :install_dir, :target

    def initialize(base_dir, install_dir, target)
      @base_dir = base_dir
      @install_dir = install_dir
      @target = target
    end

    def define_task
      libyaml_version = "0.2.5"
      desc "build libyaml #{libyaml_version} for #{target}"
      task "libyaml-#{target}" do
        next if Dir.exist?("#{install_dir}/libyaml")

        build_dir = File.join(base_dir, "/build/deps/#{target}/yaml-#{libyaml_version}")
        mkdir_p File.dirname(build_dir)
        rm_rf build_dir
        sh "curl -L https://github.com/yaml/libyaml/releases/download/#{libyaml_version}/yaml-#{libyaml_version}.tar.gz | tar xz", chdir: File.dirname(build_dir)

        # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
        sh "curl -o #{build_dir}/config/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'"
        sh "curl -o #{build_dir}/config/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'"

        configure_args = []
        case target
        when "wasm32-unknown-wasi"
          configure_args.concat(%W(--host wasm32-wasi CC=#{ENV["WASI_SDK_PATH"]}/bin/clang RANLIB=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ranlib LD=#{ENV["WASI_SDK_PATH"]}/bin/clang AR=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ar))
        when "wasm32-unknown-emscripten"
          configure_args.concat(%W(--host wasm32-emscripten CC=emcc RANLIB=emranlib LD=emcc AR=emar))
        else
          raise "unknown target: #{target}"
        end
        sh "./configure #{configure_args.join(" ")}", chdir: build_dir
        sh "make install DESTDIR=#{install_dir}/libyaml", chdir: build_dir
      end
    end
  end
end