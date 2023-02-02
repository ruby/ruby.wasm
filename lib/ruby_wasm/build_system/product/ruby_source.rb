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

    def cache_key(digest)
      digest << @params[:type]
      case @params[:type]
      when "github"
        digest << @params[:rev]
      when "local"
        digest << File.mtime(@params[:src]).to_i.to_s
      else
        raise "unknown source type: #{@params[:type]}"
      end
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
        FileUtils.mkdir_p src_dir
        system "git init", chdir: src_dir
        system "git remote add origin #{repo_url}", chdir: src_dir
        system("git fetch --depth 1 origin #{@params[:rev]}:#{@params[:rev]}", chdir: src_dir) or
          raise "failed to clone #{repo_url}"
        system("git checkout #{@params[:rev]}", chdir: src_dir) or
          raise "failed to checkout #{@params[:rev]}"
      when "local"
        FileUtils.mkdir_p File.dirname(src_dir)
        FileUtils.cp_r @params[:src], src_dir
      else
        raise "unknown source type: #{@params[:type]}"
      end
      (@params[:patches] || []).each do |patch_path|
        system "patch -p1 < #{patch_path}", chdir: src_dir
      end
    end

    def build
      fetch unless File.exist?(src_dir)
      unless File.exist?(configure_file)
        Dir.chdir(src_dir) do
          system "ruby tool/downloader.rb -d tool -e gnu config.guess config.sub" or
            raise "failed to download config.guess and config.sub"
          system "./autogen.sh" or raise "failed to run autogen.sh"
        end
      end
    end
  end
end
