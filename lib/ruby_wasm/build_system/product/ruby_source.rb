require "rake"
require_relative "./product"

module RubyWasm
  class BuildSource < BuildProduct
    def initialize(params, build_dir)
      @params = params
      @build_dir = build_dir
    end

    def name
      @params[:name]
    end

    def src_dir
      File.join(@build_dir, "checkouts", @params[:name])
    end

    def configure_file
      File.join(src_dir, "configure")
    end

    def fetch
      case @params[:type]
      when "github"
        repo_url = "https://github.com/#{@params[:repo]}.git"
        mkdir_p src_dir
        sh "git init", chdir: src_dir
        sh "git remote add origin #{repo_url}", chdir: src_dir
        sh "git fetch --depth 1 origin #{@params[:rev]}", chdir: src_dir
        sh "git checkout #{@params[:rev]}", chdir: src_dir
      else
        raise "unknown source type: #{@params[:type]}"
      end
    end

    def define_task
      directory src_dir do
        fetch
      end
      file configure_file => [src_dir] do
        sh "ruby tool/downloader.rb -d tool -e gnu config.guess config.sub",
           chdir: src_dir
        sh "./autogen.sh", chdir: src_dir
      end
    end
  end
end
