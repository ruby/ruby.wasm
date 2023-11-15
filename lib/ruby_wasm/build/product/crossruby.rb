require_relative "./product"

module RubyWasm
  class CrossRubyExtProduct < BuildProduct
    attr_reader :name
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

    def build(executor, crossruby)
      lib = @name
      objdir = product_build_dir crossruby
      executor.mkdir_p objdir
      do_extconf executor, crossruby
      executor.system "make",
                      "-C",
                      "#{objdir}",
                      *make_args(crossruby),
                      "#{lib}.a"
      # A ext can provide link args by link.filelist. It contains only built archive file by default.
      unless File.exist?(linklist(crossruby))
        executor.write(
          linklist(crossruby),
          Dir.glob("#{objdir}/*.a").join("\n")
        )
      end
    end

    def do_extconf(executor, crossruby)
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
      executor.system crossruby.baseruby_path,
                      *extconf_args,
                      chdir: objdir,
                      env: {
                        "RUBYOPT" => ""
                      }
    end

    def do_install_rb(executor, crossruby)
      objdir = product_build_dir crossruby
      executor.system "make", "-C", objdir, *make_args(crossruby), "install-rb"
    end

    def cache_key(digest)
      digest << @name
      # Compute hash value of files under srcdir
      Dir
        .glob("#{@srcdir}/**/*", File::FNM_DOTMATCH)
        .each do |f|
          next if File.directory?(f)
          digest << f
          digest << File.read(f)
        end
    end
  end

  class CrossRubyProduct < AutoconfProduct
    attr_reader :source, :toolchain
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

    def configure(executor, reconfigure: false)
      if !File.exist?("#{build_dir}/Makefile") || reconfigure
        args = configure_args(RbConfig::CONFIG["host"], toolchain)
        executor.system source.configure_file, *args, chdir: build_dir
      end
      # NOTE: we need rbconfig.rb at configuration time to build user given extensions with mkmf
      executor.system "make", "rbconfig.rb", chdir: build_dir
    end

    def build_exts(executor)
      @user_exts.each { |prod| prod.build(executor, self) }
      executor.mkdir_p File.dirname(extinit_obj)
      executor.system "ruby",
                      extinit_c_erb,
                      *@user_exts.map(&:name),
                      "--cc",
                      toolchain.cc,
                      "--output",
                      extinit_obj
    end

    def build(executor, remake: false, reconfigure: false)
      executor.mkdir_p dest_dir
      executor.mkdir_p build_dir
      @toolchain.install
      [@source, @baseruby, @libyaml, @zlib, @openssl, @wasi_vfs].each do |prod|
        prod.build(executor)
      end
      configure(executor, reconfigure: reconfigure)
      build_exts(executor)

      install_dir = File.join(build_dir, "install")
      if !File.exist?(install_dir) || remake || reconfigure
        executor.system "make",
                        "install",
                        "DESTDIR=#{install_dir}",
                        chdir: build_dir
      end

      executor.rm_rf dest_dir
      executor.cp_r install_dir, dest_dir
      @user_exts.each { |ext| ext.do_install_rb(executor, self) }
      executor.system "tar", "cfz", artifact, "-C", "rubies", name
    end

    def clean(executor)
      executor.rm_rf dest_dir
      executor.rm_rf build_dir
      executor.rm_rf ext_build_dir
      executor.rm_f artifact
    end

    def name
      @params.name
    end

    def cache_key(digest)
      digest << @params.target
      digest << @params.default_exts
      @wasmoptflags.each { |f| digest << f }
      @cppflags.each { |f| digest << f }
      @cflags.each { |f| digest << f }
      @ldflags.each { |f| digest << f }
      @debugflags.each { |f| digest << f }
      @xcflags.each { |f| digest << f }
      @xldflags.each { |f| digest << f }
      @user_exts.each { |ext| ext.cache_key(digest) }
    end

    def build_dir
      File.join(@build_dir, @params.target, name)
    end

    def ext_build_dir
      File.join(@build_dir, @params.target, name + "-ext")
    end

    def with_libyaml(libyaml)
      @libyaml = libyaml
    end

    def with_zlib(zlib)
      @zlib = zlib
    end

    def with_wasi_vfs(wasi_vfs)
      @wasi_vfs = wasi_vfs
    end

    def with_openssl(openssl)
      @openssl = openssl
    end

    def dest_dir
      File.join(@rubies_dir, name)
    end

    def artifact
      File.join(@rubies_dir, "ruby-#{name}.tar.gz")
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

    def configure_args(build_triple, toolchain)
      target = @params.target
      default_exts = @params.default_exts

      ldflags = @ldflags.dup
      xldflags = @xldflags.dup

      args = self.system_triplet_args + ["--build", build_triple]
      args << "--with-static-linked-ext"
      args << %Q(--with-ext=#{default_exts})
      args << %Q(--with-libyaml-dir=#{@libyaml.install_root})
      args << %Q(--with-zlib-dir=#{@zlib.install_root})
      args << %Q(--with-openssl-dir=#{@openssl.install_root}) if @openssl
      args << %Q(--with-baseruby=#{baseruby_path})

      case target
      when "wasm32-unknown-wasi"
        xldflags << @wasi_vfs.lib_wasi_vfs_a if @wasi_vfs
        # TODO: Find a way to force cast or update API
        # @type var wasi_sdk_path: untyped
        wasi_sdk_path = @toolchain
        args << %Q(WASMOPT=#{wasi_sdk_path.wasm_opt})
        args << %Q(WASI_SDK_PATH=#{wasi_sdk_path.wasi_sdk_path})
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

      args << %Q(LDFLAGS=#{ldflags.join(" ")})
      args << %Q(XLDFLAGS=#{xldflags.join(" ")})
      args << %Q(XCFLAGS=#{xcflags.join(" ")})
      args << %Q(debugflags=#{@debugflags.join(" ")})
      args << %Q(cppflags=#{@cppflags.join(" ")})
      unless wasmoptflags.empty?
        args << %Q(wasmoptflags=#{@wasmoptflags.join(" ")})
      end
      args << "--disable-install-doc"
      args
    end
  end
end
