require "rake"
require_relative "./product"

module RubyWasm
  class CrossRubyExtProduct < BuildProduct
    attr_reader :name, :toolchain
    def initialize(name, toolchain)
      @name, @toolchain = name, toolchain
    end

    def define_task(crossruby)
      task "#{crossruby.name}-ext-#{@name}" => [crossruby.configure] do
        make_args = []
        make_args << "CC=#{toolchain.cc}"
        make_args << "RANLIB=#{toolchain.ranlib}"
        make_args << "LD=#{toolchain.ld}"
        make_args << "AR=#{toolchain.ar}"

        lib = @name
        source = crossruby.source
        objdir = "#{crossruby.ext_build_dir}/#{lib}"
        FileUtils.mkdir_p objdir
        srcdir = "#{crossruby.base_dir}/ext/#{lib}"
        extconf_args = [
          "--disable=gems",
          # HACK: top_srcdir is required to find ruby headers
          "-e",
          %Q('$top_srcdir="#{source.src_dir}"'),
          # HACK: extout is required to find config.h
          "-e",
          %Q('$extout="#{crossruby.build_dir}/.ext"'),
          # HACK: force static ext build by imitating extmk
          "-e",
          "'$static = true; trace_var(:$static) {|v| $static = true }'",
          # HACK: $0 should be extconf.rb path due to mkmf source file detection
          # and we want to insert some hacks before it. But -e and $0 cannot be
          # used together, so we rewrite $0 in -e.
          "-e",
          %Q('$0="#{srcdir}/extconf.rb"'),
          "-e",
          %Q('require_relative "#{srcdir}/extconf.rb"'),
          "-I#{crossruby.build_dir}"
        ]
        sh "#{crossruby.baseruby_path} #{extconf_args.join(" ")}", chdir: objdir
        make_cmd = %Q(make -C "#{objdir}" #{make_args.join(" ")} static)
        sh make_cmd
        # A ext can provide link args by link.filelist. It contains only built archive file by default.
        unless File.exist?("#{objdir}/link.filelist")
          File.write(
            "#{objdir}/link.filelist",
            Dir.glob("#{objdir}/*.a").join("\n")
          )
        end
      end
    end
  end

  class CrossRubyProduct < BuildProduct
    attr_reader :params, :base_dir, :source, :toolchain, :build, :configure

    def initialize(params, base_dir, baseruby, source, toolchain)
      @params = params
      @base_dir = base_dir
      @baseruby = baseruby
      @source = source
      @toolchain = toolchain
      @dep_tasks = []
    end

    def define_task
      directory dest_dir
      directory build_dir

      @configure =
        task "#{name}-configure",
             [:reconfigure] =>
               [build_dir, source.src_dir, source.configure_file] +
                 dep_tasks do |t, args|
          args.with_defaults(reconfigure: false)

          if !File.exist?("#{build_dir}/Makefile") || args[:reconfigure]
            args = configure_args(RbConfig::CONFIG["host"], toolchain)
            sh "#{source.configure_file} #{args.join(" ")}", chdir: build_dir
          end
          # NOTE: we need rbconfig.rb at configuration time to build user given extensions with mkmf
          sh "make rbconfig.rb", chdir: build_dir
        end

      user_ext_products = @params.user_exts
      user_ext_tasks = user_ext_products.map { |prod| prod.define_task(self) }
      user_ext_names = user_ext_products.map(&:name)
      user_exts =
        task "#{name}-libs" => [@configure] + user_ext_tasks do
          mkdir_p File.dirname(extinit_obj)
          sh %Q(ruby #{base_dir}/ext/extinit.c.erb #{user_ext_names.join(" ")} | #{toolchain.cc} -c -x c - -o #{extinit_obj})
        end

      install =
        task "#{name}-install" => [@configure, user_exts, dest_dir] do
          next if File.exist?("#{dest_dir}-install")
          sh "make install DESTDIR=#{dest_dir}-install", chdir: build_dir
        end

      desc "Build #{name}"
      task name => [@configure, install, dest_dir] do
        artifact = "rubies/ruby-#{name}.tar.gz"
        next if File.exist?(artifact)
        rm_rf dest_dir
        cp_r "#{dest_dir}-install", dest_dir
        ruby_api_version =
          `#{baseruby_path} -e 'print RbConfig::CONFIG["ruby_version"]'`
        user_ext_names.each do |lib|
          next unless File.exist?("ext/#{lib}/lib")
          cp_r(
            File.join(base_dir, "ext/#{lib}/lib/."),
            File.join(dest_dir, "usr/local/lib/ruby/#{ruby_api_version}")
          )
        end
        sh "tar cfz #{artifact} -C rubies #{name}"
      end
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

    def baseruby_path
      File.join(@baseruby.install_dir, "bin/ruby")
    end

    def dep_tasks
      return [@baseruby.build_task] if @params.profile == "minimal"
      [
        @baseruby.build_task,
        "deps:libyaml-#{@params[:target]}",
        "deps:zlib-#{@params[:target]}"
      ]
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
        unless toolchain.lib_wasi_vfs_a.nil?
          xldflags << toolchain.lib_wasi_vfs_a
        end
      when "wasm32-unknown-emscripten"
        ldflags.concat(%w[-s MODULARIZE=1])
        args.concat(%w[CC=emcc LD=emcc AR=emar RANLIB=emranlib])
      else
        raise "unknown target: #{target}"
      end

      (user_exts || []).each do |lib|
        xldflags << "@#{ext_build_dir}/#{lib.name}/link.filelist"
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
