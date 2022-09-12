require "rake"
require_relative "./product"

module RubyWasm
  class ZlibProduct < AutoconfProduct
    attr_reader :base_dir, :install_dir, :target, :install_task

    def initialize(base_dir, install_dir, target, toolchain)
      @base_dir = base_dir
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

          build_dir =
            File.join(base_dir, "/build/deps/#{target}/zlib-#{zlib_version}")
          mkdir_p File.dirname(build_dir)
          rm_rf build_dir

          sh "curl -L https://zlib.net/zlib-#{zlib_version}.tar.gz | tar xz",
             chdir: File.dirname(build_dir)

          sh "#{tools_args.join(" ")} ./configure --prefix=#{install_root} --static",
             chdir: build_dir
          sh "make install", chdir: build_dir
        end
    end
  end
end
