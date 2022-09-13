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
    @toolchain = toolchain || RubyWasm::Toolchain.get(target)

    @libyaml =
      add_product RubyWasm::LibYAMLProduct.new(@build_dir, @target, @toolchain)
    @zlib =
      add_product RubyWasm::ZlibProduct.new(@build_dir, @target, @toolchain)
    @source = add_product RubyWasm::BuildSource.new(src, @build_dir)
    @baseruby = add_product RubyWasm::BaseRubyProduct.new(@build_dir, @source)

    build_params =
      RubyWasm::BuildParams.new(options.merge(name: name, target: @target))

    @crossruby =
      add_product RubyWasm::CrossRubyProduct.new(
                    build_params,
                    @build_dir,
                    @rubies_dir,
                    @baseruby,
                    @source,
                    @toolchain
                  )
    yield self if block_given?

    @products_to_define.each(&:define_task)

    @crossruby.with_libyaml @libyaml
    @crossruby.with_zlib @zlib

    @crossruby.define_task
  end

  private

  def add_product(product)
    @@products ||= {}
    return @@products[product.name] if @@products[product.name]
    @@products[product.name] = product
    @products_to_define ||= []
    @products_to_define << product
    product
  end
end
