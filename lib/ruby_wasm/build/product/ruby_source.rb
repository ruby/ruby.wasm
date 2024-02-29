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
      when "tarball"
        digest << @params[:url]
      when "local"
        digest << File.mtime(@params[:path]).to_i.to_s
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

    def fetch(executor)
      case @params[:type]
      when "github"
        repo_url = "https://github.com/#{@params[:repo]}.git"
        executor.mkdir_p src_dir
        executor.system "git", "init", chdir: src_dir
        executor.system "git",
                        "remote",
                        "add",
                        "origin",
                        repo_url,
                        chdir: src_dir
        executor.system(
          "git",
          "fetch",
          "--depth",
          "1",
          "origin",
          "#{@params[:rev]}:origin/#{@params[:rev]}",
          chdir: src_dir
        )
        executor.system(
          "git",
          "checkout",
          "origin/#{@params[:rev]}",
          chdir: src_dir
        )
      when "tarball"
        executor.mkdir_p src_dir
        tarball_path =
          File.join(File.dirname(src_dir), File.basename(src_dir) + ".tar.gz")
        executor.system("curl", "-L", "-o", tarball_path, @params[:url])
        executor.system(
          "tar",
          "xf",
          tarball_path,
          "-C",
          src_dir,
          "--strip-components=1"
        )
      when "local"
        executor.mkdir_p File.dirname(src_dir)
        executor.ln_s File.expand_path(@params[:path]), src_dir
      else
        raise "unknown source type: #{@params[:type]}"
      end
      (@params[:patches] || []).each do |patch_path|
        executor.system "patch", "-p1", "-i", patch_path, chdir: src_dir
      end
    end

    def build(executor)
      fetch(executor) unless File.exist?(src_dir)
      unless File.exist?(configure_file)
        executor.system "ruby",
                        "tool/downloader.rb",
                        "-d",
                        "tool",
                        "-e",
                        "gnu",
                        "config.guess",
                        "config.sub",
                        chdir: src_dir
        executor.system "./autogen.sh", chdir: src_dir
      end
    end
  end
end
