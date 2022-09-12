require "rake"
require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :target, :install_task

    ZLIB_VERSION = "1.2.12"

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
      "zlib-#{target}"
    end

    def define_task
      desc "build zlib #{ZLIB_VERSION} for #{target}"
      @install_task =
        task(name) do
          next if Dir.exist?(install_root)

          mkdir_p File.dirname(product_build_dir)
          rm_rf product_build_dir

          sh "curl -L https://zlib.net/zlib-#{ZLIB_VERSION}.tar.gz | tar xz",
             chdir: File.dirname(product_build_dir)

          sh "#{tools_args.join(" ")} ./configure --static",
             chdir: product_build_dir
          sh "make install DESTDIR=#{destdir}", chdir: product_build_dir
        end
    end
  end
end
