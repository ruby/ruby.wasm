require "rake"
require_relative "./product"

module RubyWasm
  class WasiVfsProduct < BuildProduct
    attr_reader :install_task

    WASI_VFS_VERSION = "0.1.1"

    def initialize(build_dir)
      @build_dir = build_dir
    end

    def lib_product_build_dir
      File.join(
        @build_dir,
        "wasm32-unknown-wasi",
        "wasi-vfs-#{WASI_VFS_VERSION}"
      )
    end

    def lib_wasi_vfs_a
      ENV["LIB_WASI_VFS_A"] || File.join(lib_product_build_dir, "libwasi_vfs.a")
    end

    def name
      lib_product_build_dir
    end

    def define_task
      return if ENV["LIB_WASI_VFS_A"]
      @install_task =
        file(lib_wasi_vfs_a) do
          require "tmpdir"
          lib_wasi_vfs_url =
            "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v#{WASI_VFS_VERSION}/libwasi_vfs-wasm32-unknown-unknown.zip"
          Dir.mktmpdir do |tmpdir|
            sh "curl -L #{lib_wasi_vfs_url} -o #{tmpdir}/libwasi_vfs.zip"
            sh "unzip #{tmpdir}/libwasi_vfs.zip -d #{tmpdir}"
            mkdir_p File.dirname(lib_wasi_vfs_a)
            mv File.join(tmpdir, "libwasi_vfs.a"), lib_wasi_vfs_a
          end
        end
    end
  end
end
