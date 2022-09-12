require "rake"
require_relative "./product"

module RubyWasm
  class BuildSource < BuildProduct
    def initialize(params, base_dir)
      @params = params
      @base_dir = base_dir
    end

    def name
      @params[:name]
    end

    def src_dir
      "#{@base_dir}/build/src/#{@params[:name]}"
    end

    def configure_file
      "#{src_dir}/configure"
    end

    def fetch
      case @params[:type]
      when "github"
        tarball_url =
          "https://api.github.com/repos/#{@params[:repo]}/tarball/#{@params[:rev]}"
        mkdir_p src_dir
        sh "curl -L #{tarball_url} | tar xz --strip-components=1",
           chdir: src_dir
      else
        raise "unknown source type: #{@params[:type]}"
      end
    end

    def define_task
      directory src_dir do
        fetch
      end
      file configure_file => [src_dir] do
        sh "./autogen.sh", chdir: src_dir
      end
    end
  end
end
