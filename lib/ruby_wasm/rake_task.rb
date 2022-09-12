require "rake/tasklib"
require_relative "./build_system"

class RubyWasm::BuildTask < ::Rake::TaskLib

  def initialize(name, target:, src:, extensions: [], toolchain: nil, build_dir: nil, rubies_dir: nil, **options, &task_block)
    build_dir ||= File.join(Dir.pwd, "build")
    rubies_dir ||= File.join(Dir.pwd, "rubies")
    toolchain ||= RubyWasm::Toolchain.get target

    libyaml = add_product RubyWasm::LibYAMLProduct.new(build_dir, target, toolchain)
    zlib = add_product RubyWasm::ZlibProduct.new(build_dir, target, toolchain)

    source = add_product RubyWasm::BuildSource.new(src, build_dir)
    baseruby = add_product RubyWasm::BaseRubyProduct.new(build_dir, source)

    build_params = RubyWasm::BuildParams.new(
      options.merge(
        name: name, src: source, target: target, user_exts: extensions
      )
    )

    product = RubyWasm::CrossRubyProduct.new(build_params, build_dir, rubies_dir, baseruby, source, toolchain)
    product.with_libyaml libyaml
    product.with_zlib zlib
    product.define_task
  end

  private

  def add_product(product)
    @@products ||= {}
    if @@products[product.name]
      return @@products[product.name]
    end
    @@products[product.name] = product
    product.define_task
    product
  end
end
