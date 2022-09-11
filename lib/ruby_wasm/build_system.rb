require "rake"
require_relative "build_system/build_params"
require_relative "build_system/product"
require_relative "build_system/toolchain"

module RubyWasm
  class BuildSource
    include Rake::FileUtilsExt

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
  end

  class BuildPlan
    def initialize(params, base_dir)
      @params = params
      @base_dir = base_dir
    end

    def name
      "#{@params.src.name}-#{@params.target}-#{@params.profile}"
    end

    def build_dir
      "#{@base_dir}/build/build/#{name}"
    end

    def ext_build_dir
      "#{@base_dir}/build/ext-build/#{name}"
    end

    def deps_install_dir
      "#{@base_dir}/build/deps/#{@params.target}/opt"
    end

    def dest_dir
      "#{@base_dir}/rubies/#{name}"
    end

    def extinit_obj
      "#{ext_build_dir}/extinit.o"
    end

    def baseruby_name
      "baseruby-#{@params.src.name}"
    end

    def baseruby_path
      "#{@base_dir}/build/deps/#{RbConfig::CONFIG["host"]}/opt/#{baseruby_name}/bin/ruby"
    end

    def dep_tasks
      return [baseruby_name] if @params.profile == "minimal"
      [
        baseruby_name,
        "deps:libyaml-#{@params[:target]}",
        "deps:zlib-#{@params[:target]}"
      ]
    end

    def check_deps
      target = @params.target
      user_exts = @params.user_exts

      if user_exts.include?("js") or user_exts.include?("witapi")
        check_executable("wit-bindgen")
      end
    end

    def configure_args(build_triple, toolchain)
      target = @params.target
      default_exts = @params.default_exts
      user_exts = @params.user_exts

      ldflags =
        if @params.debug
          # use --stack-first to detect stack overflow easily
          %w[-Xlinker --stack-first -Xlinker -z -Xlinker stack-size=16777216]
        else
          %w[-Xlinker -zstack-size=16777216]
        end

      xldflags = []

      args = ["--host", target, "--build", build_triple]
      args << "--with-static-linked-ext"
      args << %Q(--with-ext="#{default_exts}")
      args << %Q(--with-libyaml-dir="#{deps_install_dir}/libyaml/usr/local")
      args << %Q(--with-zlib-dir="#{deps_install_dir}/zlib")
      args << %Q(--with-baseruby="#{baseruby_path}")

      case target
      when "wasm32-unknown-wasi"
        xldflags << toolchain.lib_wasi_vfs_a unless toolchain.lib_wasi_vfs_a.nil?
      when "wasm32-unknown-emscripten"
        ldflags.concat(%w[-s MODULARIZE=1])
        args.concat(%w[CC=emcc LD=emcc AR=emar RANLIB=emranlib])
      else
        raise "unknown target: #{target}"
      end

      (user_exts || []).each do |lib|
        xldflags << "@#{ext_build_dir}/#{lib}/link.filelist"
      end
      xldflags << extinit_obj

      xcflags = []
      xcflags << "-DWASM_SETJMP_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_FIBER_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_SCAN_STACK_BUFFER_SIZE=24576"

      args << %Q(LDFLAGS="#{ldflags.join(" ")}")
      args << %Q(XLDFLAGS="#{xldflags.join(" ")}")
      args << %Q(XCFLAGS="#{xcflags.join(" ")}")
      if @params.debug
        args << %Q(debugflags="-g")
        args << %Q(wasmoptflags="-O3 -g")
      else
        args << %Q(debugflags="-g0")
      end
      args << "--disable-install-doc"
      args
    end
  end
end
