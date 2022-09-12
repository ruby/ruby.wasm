require "rake"
require_relative "./product"

module RubyWasm
  class BaseRubyProduct < BuildProduct
    attr_reader :source, :install_task

    def initialize(build_dir, source)
      @build_dir = build_dir
      @source = source
      @channel = source.name
    end

    def product_build_dir
      File.join(@build_dir, RbConfig::CONFIG["host"], "baseruby-#{@channel}")
    end

    def install_dir
      File.join(product_build_dir, "opt")
    end

    def name
      "baseruby-#{@channel}"
    end

    def define_task

      directory product_build_dir

      desc "build baseruby #{@channel}"
      @install_task =
        task name => [
               source.src_dir,
               source.configure_file,
               product_build_dir
             ] do
          next if Dir.exist?(install_dir)
          sh "#{source.configure_file} --prefix=#{install_dir} --disable-install-doc",
             chdir: product_build_dir
          sh "make install", chdir: product_build_dir
        end
    end
  end
end
