require "rake"
require_relative "./product"

module RubyWasm
  class OpenSSLProduct < AutoconfProduct
    attr_reader :target

    OPENSSL_VERSION = "3.0.5"

    def initialize(build_dir, target, toolchain)
      @build_dir = build_dir
      @target = target
      super(target, toolchain)
    end

    def product_build_dir
      File.join(@build_dir, target, "openssl-#{OPENSSL_VERSION}")
    end

    def destdir
      File.join(product_build_dir, "opt")
    end

    def install_root
      File.join(destdir, "usr", "local")
    end

    def name
      product_build_dir
    end

    def configure_args
      args = %w[
        gcc
        -static
        -no-asm
        -no-threads
        -no-afalgeng
        -no-ui-console
        -no-tests
        -no-sock
        -no-dgram
        --libdir=lib
        -DNO_SYSLOG
        -Wl,--allow-undefined
      ]
      if @target == "wasm32-unknown-wasi"
        args.concat %w[
                      -D_WASI_EMULATED_SIGNAL
                      -D_WASI_EMULATED_PROCESS_CLOCKS
                      -D_WASI_EMULATED_MMAN
                    ]
      end
      args + tools_args
    end

    def build(executor)
      return if Dir.exist?(install_root)

      executor.mkdir_p File.dirname(product_build_dir)
      executor.rm_rf product_build_dir
      executor.system "curl -L https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz | tar xz",
                      chdir: File.dirname(product_build_dir)

      executor.system "./Configure #{configure_args.join(" ")}",
                      chdir: product_build_dir
      # Use "install_sw" instead of "install" because it tries to install docs and it's very slow.
      # OpenSSL build system doesn't have well support for parallel build, so force -j1.
      executor.system "make -j1 install_sw DESTDIR=#{destdir}",
                      chdir: product_build_dir
    end
  end
end
