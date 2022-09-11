require "rake"
require_relative "./product"

module RubyWasm
  class ZlibTask < BuildProduct
    attr_reader :base_dir, :install_dir, :target

    def initialize(base_dir, install_dir, target)
      @base_dir = base_dir
      @install_dir = install_dir
      @target = target
    end

    def define_task(toolchain)
      zlib_version = "1.2.12"
      desc "build zlib #{zlib_version} for #{target}"
      task "zlib-#{target}" do
        next if Dir.exist?("#{install_dir}/zlib")

        build_dir = File.join(base_dir, "/build/deps/#{target}/zlib-#{zlib_version}")
        mkdir_p File.dirname(build_dir)
        rm_rf build_dir

        sh "curl -L https://zlib.net/zlib-#{zlib_version}.tar.gz | tar xz", chdir: File.dirname(build_dir)

        configure_args = []
        configure_args << "CC=#{toolchain.cc}"
        configure_args << "RANLIB=#{toolchain.ranlib}"
        configure_args << "LD=#{toolchain.ld}"
        configure_args << "AR=#{toolchain.ar}"
        sh "#{configure_args.join(" ")} ./configure --prefix=#{install_dir}/zlib --static", chdir: build_dir
        sh "make install", chdir: build_dir
      end
    end
  end
end