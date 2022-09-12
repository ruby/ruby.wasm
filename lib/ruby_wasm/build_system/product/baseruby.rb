require "rake"
require_relative "./product"

module RubyWasm
  class BaseRubyProduct < BuildProduct
    attr_reader :base_dir, :source, :install_task

    def initialize(channel, base_dir, source)
      @channel = channel
      @base_dir = base_dir
      @source = source
    end

    def install_dir
      File.join(
        base_dir,
        "/build/deps/#{RbConfig::CONFIG["host"]}/opt/baseruby-#{@channel}"
      )
    end

    def name
      "baseruby-#{@channel}"
    end

    def define_task
      baseruby_build_dir =
        File.join(
          base_dir,
          "/build/deps/#{RbConfig::CONFIG["host"]}/baseruby-#{@channel}"
        )

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
