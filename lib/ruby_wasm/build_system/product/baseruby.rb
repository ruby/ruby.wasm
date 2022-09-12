require "rake"
require_relative "./product"

module RubyWasm
  class BaseRubyTask < BuildProduct
    attr_reader :name, :base_dir

    def initialize(name, base_dir)
      @name = name
      @base_dir = base_dir
    end

    def define_task(source)
      directory source.src_dir do
        source.fetch
      end
      file source.configure_file => [source.src_dir] do
        sh "./autogen.sh", chdir: source.src_dir
      end

      baseruby_install_dir = File.join(base_dir, "/build/deps/#{RbConfig::CONFIG["host"]}/opt/baseruby-#{name}")
      baseruby_build_dir   = File.join(base_dir, "/build/deps/#{RbConfig::CONFIG["host"]}/baseruby-#{name}")

      directory baseruby_build_dir

      desc "build baseruby #{name}"
      task "baseruby-#{name}" => [source.src_dir, source.configure_file, baseruby_build_dir] do
        next if Dir.exist?(baseruby_install_dir)
        sh "#{source.configure_file} --prefix=#{baseruby_install_dir} --disable-install-doc", chdir: baseruby_build_dir
        sh "make install", chdir: baseruby_build_dir
      end
    end
  end
end