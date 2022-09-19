require "rake"
require_relative "./product"

module RubyWasm
  class CrossRubyExtProduct < BuildProduct
    attr_reader :name, :srcdir
    def initialize(srcdir, toolchain, name: nil)
      @srcdir, @toolchain = srcdir, toolchain
      @name = name || File.basename(srcdir)
    end

    def product_build_dir(crossruby)
      File.join(crossruby.ext_build_dir, @name)
    end

    def linklist(crossruby)
      File.join(product_build_dir(crossruby), "link.filelist")
    end

    def make_args(crossruby)
      make_args = []
      make_args << "CC=#{@toolchain.cc}"
      make_args << "LD=#{@toolchain.ld}"
      make_args << "AR=#{@toolchain.ar}"
      make_args << "RANLIB=#{@toolchain.ranlib}"

      make_args << "DESTDIR=#{crossruby.dest_dir}"
      make_args
    end

    def define_task(crossruby)
      task "#{crossruby.name}-ext-#{@name}" => [crossruby.configure] do
        lib = @name
        objdir = product_build_dir crossruby
        FileUtils.mkdir_p objdir
        do_extconf crossruby
        sh %Q(make -C "#{objdir}" #{make_args(crossruby).join(" ")} #{lib}.a)
        # A ext can provide link args by link.filelist. It contains only built archive file by default.
        unless File.exist?(linklist(crossruby))
          File.write(linklist(crossruby), Dir.glob("#{objdir}/*.a").join("\n"))
        end
      end
    end

    def do_extconf(crossruby)
      objdir = product_build_dir crossruby
      source = crossruby.source
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
        %Q('$0="#{@srcdir}/extconf.rb"'),
        "-e",
        %Q('require_relative "#{@srcdir}/extconf.rb"'),
        "-I#{crossruby.build_dir}"
      ]
      # Clear RUBYOPT to avoid loading unrelated bundle setup
      sh ({ "RUBYOPT" => "" }),
         "#{crossruby.baseruby_path} #{extconf_args.join(" ")}",
         chdir: objdir
    end

    def do_install_rb(crossruby)
      objdir = product_build_dir crossruby
      sh %Q(make -C "#{objdir}" #{make_args(crossruby).join(" ")} install-rb)
    end
  end

  class CrossRubyProduct < AutoconfProduct
    attr_reader :source, :toolchain, :build, :configure
    attr_accessor :user_exts,
                  :wasmoptflags,
                  :cppflags,
                  :cflags,
                  :ldflags,
                  :debugflags,
                  :xcflags,
                  :xldflags

    def initialize(
      params,
      build_dir,
      rubies_dir,
      baseruby,
      source,
      toolchain,
      user_exts: []
    )
      @params = params
      @rubies_dir = rubies_dir
      @build_dir = build_dir
      @baseruby = baseruby
      @source = source
      @toolchain = toolchain
      @dep_tasks = []
      @user_exts = user_exts
      @wasmoptflags = []
      @cppflags = []
      @cflags = []
      @ldflags = []
      @debugflags = []
      @xcflags = []
      @xldflags = []
      super(@params.target, @toolchain)
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

      user_ext_products = @user_exts
      user_ext_tasks = @user_exts.map { |prod| prod.define_task(self) }
      extinit_task =
        task extinit_obj => [@configure, extinit_c_erb] + user_ext_tasks do
          mkdir_p File.dirname(extinit_obj)
          sh %Q(ruby #{extinit_c_erb} #{@user_exts.map(&:name).join(" ")} | #{toolchain.cc} -c -x c - -o #{extinit_obj})
        end

      install_dir = File.join(build_dir, "install")
      install =
        task install_dir => [@configure, extinit_task, dest_dir] do
          next if File.exist?(install_dir)
          sh "make install DESTDIR=#{install_dir}", chdir: build_dir
        end

      desc "Build #{name}"
      task name => [@configure, install, dest_dir] do
        artifact = "rubies/ruby-#{name}.tar.gz"
        next if File.exist?(artifact)
        rm_rf dest_dir
        cp_r install_dir, dest_dir
        @user_exts.each { |ext| ext.do_install_rb(self) }
        sh "tar cfz #{artifact} -C rubies #{name}"
      end
    end

    def name
      @params.name
    end

    def build_dir
      File.join(@build_dir, @params.target, name)
    end

    def ext_build_dir
      File.join(@build_dir, @params.target, name + "-ext")
    end

    def with_libyaml(libyaml)
      @libyaml = libyaml
      @dep_tasks << libyaml.install_task
    end

    def with_zlib(zlib)
      @zlib = zlib
      @dep_tasks << zlib.install_task
    end

    def with_wasi_vfs(wasi_vfs)
      @wasi_vfs = wasi_vfs
      install_task = wasi_vfs.install_task
      @dep_tasks << install_task if install_task
    end

    def dest_dir
      File.join(@rubies_dir, name)
    end

    def extinit_obj
      "#{ext_build_dir}/extinit.o"
    end

    def extinit_c_erb
      lib_root = File.expand_path("../../../../..", __FILE__)
      File.join(lib_root, "ext", "extinit.c.erb")
    end

    def baseruby_path
      File.join(@baseruby.install_dir, "bin/ruby")
    end

    def dep_tasks
      [@baseruby.install_task, @toolchain.install_task] + @dep_tasks
    end

    def configure_args(build_triple, toolchain)
      target = @params.target
      default_exts = @params.default_exts

      ldflags = @ldflags.dup
      xldflags = @xldflags.dup

      args = self.system_triplet_args + ["--build", build_triple]
      args << "--with-static-linked-ext"
      args << %Q(--with-ext="#{default_exts}")
      args << %Q(--with-libyaml-dir="#{@libyaml.install_root}")
      args << %Q(--with-zlib-dir="#{@zlib.install_root}")
      args << %Q(--with-baseruby="#{baseruby_path}")

      case target
      when "wasm32-unknown-wasi"
        xldflags << @wasi_vfs.lib_wasi_vfs_a if @wasi_vfs
        args << %Q(WASMOPT=#{@toolchain.wasm_opt})
      when "wasm32-unknown-emscripten"
        ldflags.concat(%w[-s MODULARIZE=1])
      else
        raise "unknown target: #{target}"
      end

      args.concat(self.tools_args)
      (@user_exts || []).each { |lib| xldflags << "@#{lib.linklist(self)}" }
      xldflags << extinit_obj

      xcflags = @xcflags.dup
      xcflags << "-DWASM_SETJMP_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_FIBER_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_SCAN_STACK_BUFFER_SIZE=24576"

      args << %Q(LDFLAGS="#{ldflags.join(" ")}")
      args << %Q(XLDFLAGS="#{xldflags.join(" ")}")
      args << %Q(XCFLAGS="#{xcflags.join(" ")}")
      args << %Q(debugflags="#{@debugflags.join(" ")}")
      args << %Q(cppflags="#{@cppflags.join(" ")}")
      unless wasmoptflags.empty?
        args << %Q(wasmoptflags="#{@wasmoptflags.join(" ")}")
      end
      args << "--disable-install-doc"
      args
    end
  end
end
