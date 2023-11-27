require_relative "./product"

module RubyWasm
  class BaseRubyProduct < BuildProduct
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

    def build(executor)
      executor.mkdir_p product_build_dir
      @source.build(executor)
      return if Dir.exist?(install_dir)
      executor.system @source.configure_file,
                      "--prefix=#{install_dir}",
                      "--disable-install-doc",
                      chdir: product_build_dir
      executor.system "make",
                      "-j#{executor.process_count}",
                      "install",
                      chdir: product_build_dir
    end
  end
end
