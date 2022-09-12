require "rake"
require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :install_dir, :target, :install_task

    def initialize(build_dir, install_dir, target, toolchain)
      @build_dir = build_dir
      @install_dir = install_dir
      @target = target
      super(target, toolchain)
    end

    def install_root
      File.join(install_dir, "zlib")
    end

    def name
      "zlib-#{target}"
    end

    def define_task
      zlib_version = "1.2.12"
      desc "build zlib #{zlib_version} for #{target}"
      @install_task =
        task(name) do
          next if Dir.exist?(install_root)

          product_build_dir =
            File.join(@build_dir, target, "zlib-#{zlib_version}")
          mkdir_p File.dirname(product_build_dir)
          rm_rf product_build_dir

          sh "curl -L https://zlib.net/zlib-#{zlib_version}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

          sh "#{tools_args.join(" ")} ./configure --prefix=#{install_root} --static",
             chdir: product_build_dir
          sh "make install", chdir: product_build_dir
        end
    end
  end
end
