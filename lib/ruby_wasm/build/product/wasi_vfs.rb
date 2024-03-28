require_relative "./product"

module RubyWasm
  class WasiVfsProduct < BuildProduct
    WASI_VFS_VERSION = "0.5.0"

    def initialize(build_dir)
      @build_dir = build_dir
      @need_fetch_lib = ENV["LIB_WASI_VFS_A"].nil?
    end

    def lib_product_build_dir
      File.join(
        @build_dir,
        "wasm32-unknown-wasip1",
        "wasi-vfs-#{WASI_VFS_VERSION}"
      )
    end

    def lib_wasi_vfs_a
      ENV["LIB_WASI_VFS_A"] || File.join(lib_product_build_dir, "libwasi_vfs.a")
    end

    def name
      "wasi-vfs-#{WASI_VFS_VERSION}-#{RbConfig::CONFIG["host"]}"
    end

    def build(executor)
      return if !@need_fetch_lib || File.exist?(lib_wasi_vfs_a)
      require "tmpdir"
      lib_wasi_vfs_url =
        "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v#{WASI_VFS_VERSION}/libwasi_vfs-wasm32-unknown-unknown.zip"
      Dir.mktmpdir do |tmpdir|
        executor.system "curl",
                        "-L",
                        lib_wasi_vfs_url,
                        "-o",
                        "#{tmpdir}/libwasi_vfs.zip"
        executor.system "unzip", "#{tmpdir}/libwasi_vfs.zip", "-d", tmpdir
        executor.mkdir_p File.dirname(lib_wasi_vfs_a)
        executor.mv File.join(tmpdir, "libwasi_vfs.a"), lib_wasi_vfs_a
      end
    end
  end
end
