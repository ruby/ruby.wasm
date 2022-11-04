require "rake/tasklib"
require_relative "./build_system"

class RubyWasm::BuildTask < ::Rake::TaskLib
  # Name of the task.
  attr_accessor :name

  # Source to build from.
  attr_reader :source

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
    toolchain: nil,
    build_dir: nil,
    rubies_dir: nil,
    **options
  )
    @name = name
    @target = target
    @build_dir = build_dir || File.join(Dir.pwd, "build")
    @rubies_dir = rubies_dir || File.join(Dir.pwd, "rubies")
    @toolchain = (toolchain || RubyWasm::Toolchain.get(target, @build_dir))

    @libyaml = RubyWasm::LibYAMLProduct.new(@build_dir, @target, @toolchain)
    @zlib = RubyWasm::ZlibProduct.new(@build_dir, @target, @toolchain)
    @wasi_vfs = RubyWasm::WasiVfsProduct.new(@build_dir)
    @source = RubyWasm::BuildSource.new(src, @build_dir)
    @baseruby = RubyWasm::BaseRubyProduct.new(@build_dir, @source)

    build_params =
      RubyWasm::BuildParams.new(options.merge(name: name, target: @target))

    @crossruby =
      RubyWasm::CrossRubyProduct.new(
        build_params,
        @build_dir,
        @rubies_dir,
        @baseruby,
        @source,
        @toolchain
      )
    yield self if block_given?

    @crossruby.with_libyaml @libyaml
    @crossruby.with_zlib @zlib
    @crossruby.with_wasi_vfs @wasi_vfs

    desc "Cross-build Ruby for #{@target}"
    task name do
      next if @crossruby.built?
      @crossruby.build
    end
    namespace name do
      task :remake do
        @crossruby.build(remake: true)
      end
      task :reconfigure do
        @crossruby.build(reconfigure: true)
      end
      task :clean do
        @crossruby.clean
      end
    end
  end

  def hexdigest
    require "digest"
    digest = Digest::SHA256.new
    digest << @source.name
    digest << @build_dir
    digest << @rubies_dir
    digest << @target
    digest << @toolchain.name
    digest << @libyaml.name
    digest << @zlib.name
    digest << @wasi_vfs.name
    digest.hexdigest
  end
end
