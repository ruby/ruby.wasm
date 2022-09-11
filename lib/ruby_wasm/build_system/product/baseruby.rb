require "rake"
require_relative "./product"

module RubyWasm
  class BaseRubyProduct < BuildProduct
    attr_reader :name, :base_dir, :source, :build_task

    def initialize(name, base_dir, source)
      @name = name
      @base_dir = base_dir
      @source = source
    end

    def install_dir
      File.join(
        base_dir,
        "/build/deps/#{RbConfig::CONFIG["host"]}/opt/baseruby-#{name}"
      )
    end

    def define_task
      baseruby_build_dir =
        File.join(
          base_dir,
          "/build/deps/#{RbConfig::CONFIG["host"]}/baseruby-#{name}"
        )

      directory baseruby_build_dir

      desc "build baseruby #{name}"
      @build_task =
        task "baseruby-#{name}" => [
               source.src_dir,
               source.configure_file,
               baseruby_build_dir
             ] do
          next if Dir.exist?(install_dir)
          sh "#{source.configure_file} --prefix=#{install_dir} --disable-install-doc",
             chdir: baseruby_build_dir
          sh "make install", chdir: baseruby_build_dir
        end
    end
  end
end
