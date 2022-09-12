require "rake"
require_relative "./product"

module RubyWasm
  class BaseRubyProduct < BuildProduct
    attr_reader :base_dir, :source, :install_task

    def initialize(build_dir, source)
      @build_dir = build_dir
      @source = source
      @channel = source.name
    end

    def install_dir
      File.join(
        @build_dir, RbConfig::CONFIG["host"], "opt", "baseruby-#{@channel}"
      )
    end

    def name
      "baseruby-#{@channel}"
    end

    def define_task
      baseruby_build_dir =
        File.join(@build_dir, RbConfig::CONFIG["host"], "baseruby-#{@channel}")

      directory baseruby_build_dir

      desc "build baseruby #{@channel}"
      @install_task =
        task name => [
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
