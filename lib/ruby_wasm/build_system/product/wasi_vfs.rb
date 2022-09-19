require "rake"
require_relative "./product"

module RubyWasm
  class WasiVfsProduct < BuildProduct
    attr_reader :install_task, :cli_install_task

    WASI_VFS_VERSION = "0.1.1"

    def initialize(build_dir)
      @build_dir = build_dir
      @cli_path = ENV["WASI_VFS_CLI"] || Toolchain.find_path("wasi-vfs")
      @need_fetch_cli = @cli_path.nil?
      @cli_path ||= File.join(cli_product_build_dir, "wasi-vfs")
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

    def cli_product_build_dir
      File.join(
        @build_dir,
        RbConfig::CONFIG["host"],
        "wasi-vfs-#{WASI_VFS_VERSION}"
      )
    end

    def cli_bin_path
      @cli_path
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

      file(cli_bin_path) do
        mkdir_p cli_product_build_dir
        zipfiel = File.join(cli_product_build_dir, "wasi-vfs-cli.zip")
        sh "curl -L -o #{zipfiel} #{self.cli_download_url}"
        sh "unzip #{zipfiel} -d #{cli_product_build_dir}"
      end
      cli_install_deps = @need_fetch_cli ? [cli_bin_path] : []
      @cli_install_task = task "wasi-vfs-cli:install" => cli_install_deps
    end

    def cli_download_url
      assets = [
        [/x86_64-linux/, "wasi-vfs-cli-x86_64-unknown-linux-gnu.zip"],
        [/x86_64-darwin/, "wasi-vfs-cli-x86_64-apple-darwin.zip"],
        [/arm64-darwin/, "wasi-vfs-cli-aarch64-apple-darwin.zip"]
      ]
      asset = assets.find { |os, _| os =~ RUBY_PLATFORM }&.at(1)
      if asset.nil?
        raise "unsupported platform for fetching wasi-vfs CLI: #{RUBY_PLATFORM}"
      end
      "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v#{WASI_VFS_VERSION}/#{asset}"
    end
  end
end
