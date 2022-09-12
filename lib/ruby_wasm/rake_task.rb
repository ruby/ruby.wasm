require "rake/tasklib"
require_relative "./build_system"

class RubyWasm::BuildTask < ::Rake::TaskLib

  def initialize(name, target:, src:, extensions: [], toolchain: nil, **options, &task_block)
    base_dir = Dir.pwd
    install_dir = File.join(base_dir, "/build/deps/#{target}/opt")
    toolchain ||= RubyWasm::Toolchain.get target

    libyaml = add_product RubyWasm::LibYAMLProduct.new(base_dir, install_dir, target, toolchain)
    zlib = add_product RubyWasm::ZlibProduct.new(base_dir, install_dir, target, toolchain)

    source = add_product RubyWasm::BuildSource.new(src, base_dir)
    baseruby = add_product RubyWasm::BaseRubyProduct.new(name, base_dir, source)

    build_params = RubyWasm::BuildParams.new(
      options.merge(
        name: name, src: source, target: target, user_exts: extensions
      )
    )

    exts = extensions.map do |ext|
      RubyWasm::CrossRubyExtProduct.new(ext, toolchain)
    end
    product = RubyWasm::CrossRubyProduct.new(build_params, base_dir, baseruby, source, toolchain)
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
