require_relative "build/build_params"
require_relative "build/product"
require_relative "build/toolchain"
require_relative "build/executor"
require_relative "build/target"

class RubyWasm::Build
  # Source to build from.
  attr_reader :source

  # Target to build for.
  attr_reader :target

  # Toolchain for the build.
  # Defaults to the Toolchain.get for the target.
  attr_reader :toolchain

  # LibYAML product to build.
  attr_reader :libyaml

  # zlib product to build.
  attr_reader :zlib

  # wasi-vfs product used by the crossruby.
  attr_reader :wasi_vfs

  # BaseRuby product to build.
  attr_reader :baseruby

  # CrossRuby product to build.
  attr_reader :crossruby

  def initialize(
    name,
    target:,
    src:,
    toolchain:,
    build_dir:,
    rubies_dir:,
    wasi_vfs: :default,
    **options
  )
    @target = target
    @build_dir = build_dir
    @rubies_dir = rubies_dir
    @toolchain = (toolchain || RubyWasm::Toolchain.get(target, @build_dir))

    @libyaml = RubyWasm::LibYAMLProduct.new(@build_dir, @target, @toolchain)
    @zlib = RubyWasm::ZlibProduct.new(@build_dir, @target, @toolchain)
    @wasi_vfs = wasi_vfs == :default ? RubyWasm::WasiVfsProduct.new(@build_dir) : wasi_vfs
    @source = RubyWasm::BuildSource.new(src, @build_dir)
    @baseruby = RubyWasm::BaseRubyProduct.new(@build_dir, @source)
    @openssl = RubyWasm::OpenSSLProduct.new(@build_dir, @target, @toolchain)

    build_params =
      RubyWasm::BuildParams.new(
        name: name,
        target: target,
        default_exts: options[:default_exts]
      )

    @crossruby =
      RubyWasm::CrossRubyProduct.new(
        build_params,
        @build_dir,
        @rubies_dir,
        @baseruby,
        @source,
        @toolchain
      )

    @crossruby.with_libyaml @libyaml
    @crossruby.with_zlib @zlib
    @crossruby.with_wasi_vfs @wasi_vfs
    @crossruby.with_openssl @openssl
  end

  def cache_key(digest)
    @source.cache_key(digest)
    @crossruby.cache_key(digest)
    digest << @build_dir
    digest << @rubies_dir
    @target.cache_key(digest)
    digest << @toolchain.name
    digest << @libyaml.name
    digest << @zlib.name
    digest << @openssl.name
    if wasi_vfs = @wasi_vfs
      digest << wasi_vfs.name
    end
  end
end
