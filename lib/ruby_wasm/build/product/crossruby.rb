require_relative "./product"
require "json"

module RubyWasm
  class CrossRubyExtProduct < BuildProduct
    attr_reader :name

    def initialize(srcdir, toolchain, ext_relative_path: nil)
      @srcdir, @toolchain = srcdir, toolchain
      # ext_relative_path is relative path from build dir
      # e.g. cgi-0.3.6/ext/cgi/escape
      @ext_relative_path = ext_relative_path || File.basename(srcdir)
      @name = @ext_relative_path
    end

    def product_build_dir(crossruby)
      File.join(crossruby.ext_build_dir, @ext_relative_path)
    end

    def linklist(crossruby)
      File.join(product_build_dir(crossruby), "link.filelist")
    end

    def metadata_json(crossruby)
      File.join(product_build_dir(crossruby), "rbwasm.metadata.json")
    end

    def feature_name(crossruby)
      metadata = JSON.parse(File.read(metadata_json(crossruby)))
      metadata["target"]
    end

    def make_args(crossruby)
      make_args = []
      make_args << "CC=#{@toolchain.cc}"
      make_args << "LD=#{@toolchain.ld}"
      make_args << "AR=#{@toolchain.ar}"
      make_args << "RANLIB=#{@toolchain.ranlib}"

      make_args
    end

    def build(executor, crossruby)
      objdir = product_build_dir crossruby
      executor.mkdir_p objdir
      do_extconf executor, crossruby
      executor.system "make",
                      "-j#{executor.process_count}",
                      "-C",
                      "#{objdir}",
                      *make_args(crossruby),
                      "static"
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
        "-C", objdir,
        "--disable=gems",
        # HACK: top_srcdir is required to find ruby headers
        "-e",
        %Q($top_srcdir="#{source.src_dir}"),
        # HACK: extout is required to find config.h
        "-e",
        %Q($extout="#{crossruby.build_dir}/.ext"),
        # HACK: force static ext build by imitating extmk
        "-e",
        "$static = true; trace_var(:$static) {|v| $static = true }",
        # HACK: $0 should be extconf.rb path due to mkmf source file detection
        # and we want to insert some hacks before it. But -e and $0 cannot be
        # used together, so we rewrite $0 in -e.
        "-e",
        %Q($0="#{@srcdir}/extconf.rb"),
        "-e",
        %Q(require_relative "#{@srcdir}/extconf.rb"),
        # HACK: extract "$target" from extconf.rb to get a full target name
        # like "cgi/escape" instead of "escape"
        "-e",
        %Q(require "json"; File.write("#{metadata_json(crossruby)}", JSON.dump({target: $target}))),
        "-I#{crossruby.build_dir}"
      ]
      # Clear RUBYOPT to avoid loading unrelated bundle setup
      executor.system crossruby.baseruby_path,
                      *extconf_args,
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

    def initialize(params, build_dir, rubies_dir, baseruby, source, toolchain)
      @params = params
      @rubies_dir = rubies_dir
      @build_dir = build_dir
      @baseruby = baseruby
      @source = source
      @toolchain = toolchain
      @user_exts = []
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

    def need_exts_build?
      @user_exts.any?
    end

    def build_exts(executor)
      @user_exts.each do |prod|
        executor.begin_section prod.class, prod.name, "Building"
        prod.build(executor, self)
        executor.end_section prod.class, prod.name
      end
    end

    def build(executor, remake: false, reconfigure: false)
      executor.mkdir_p dest_dir
      executor.mkdir_p build_dir
      @toolchain.install
      [@source, @baseruby, @libyaml, @zlib, @openssl, @wasi_vfs].each do |prod|
        next unless prod
        executor.begin_section prod.class, prod.name, "Building"
        prod.build(executor)
        executor.end_section prod.class, prod.name
      end
      executor.begin_section self.class, name, "Configuring"
      configure(executor, reconfigure: reconfigure)
      executor.end_section self.class, name

      build_exts(executor) if need_exts_build?

      executor.begin_section self.class, name, "Building"

      if need_exts_build?
        executor.mkdir_p File.dirname(extinit_obj)
        executor.system "ruby",
                        extinit_c_erb,
                        *@user_exts.map { |ext| ext.feature_name(self) },
                        "--cc",
                        toolchain.cc,
                        "--output",
                        extinit_obj
      end
      install_dir = File.join(build_dir, "install")
      if !File.exist?(install_dir) || remake || reconfigure
        executor.system "make",
                        "-j#{executor.process_count}",
                        "install",
                        "DESTDIR=#{install_dir}",
                        chdir: build_dir
      end

      executor.rm_rf dest_dir
      executor.cp_r install_dir, dest_dir
      @user_exts.each { |ext| ext.do_install_rb(executor, self) }
      executor.system "tar", "cfz", artifact, "-C", @rubies_dir, name

      executor.end_section self.class, name
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
      @params.target.cache_key(digest)
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
      File.join(@build_dir, @params.target.to_s, name)
    end

    def ext_build_dir
      File.join(@build_dir, @params.target.to_s, name + "-ext")
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
      File.join(@rubies_dir, "#{name}.tar.gz")
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
      target = @params.target.triple
      default_exts = @params.default_exts

      ldflags = @ldflags.dup
      xldflags = @xldflags.dup

      args = self.system_triplet_args + ["--build", build_triple]
      args << "--with-static-linked-ext" unless @params.target.pic?
      args << %Q(--with-ext=#{default_exts})
      args << %Q(--with-libyaml-dir=#{@libyaml.install_root})
      args << %Q(--with-zlib-dir=#{@zlib.install_root})
      args << %Q(--with-openssl-dir=#{@openssl.install_root}) if @openssl
      args << %Q(--with-baseruby=#{baseruby_path})

      case target
      when /^wasm32-unknown-wasi/
        xldflags << @wasi_vfs.lib_wasi_vfs_a if @wasi_vfs
        # TODO: Find a way to force cast or update API
        # @type var wasi_sdk_path: untyped
        wasi_sdk_path = @toolchain
        args << %Q(WASMOPT=#{wasi_sdk_path.wasm_opt})
        args << %Q(WASI_SDK_PATH=#{wasi_sdk_path.wasi_sdk_path})
      when "wasm32-unknown-emscripten"
        ldflags.concat(%w[-s MODULARIZE=1])
        env_emcc_ldflags = ENV["RUBY_WASM_EMCC_LDFLAGS"] || ""
        unless env_emcc_ldflags.empty?
          ldflags << env_emcc_ldflags
        end
      else
        raise "unknown target: #{target}"
      end

      args.concat(self.tools_args)
      (@user_exts || []).each { |lib| xldflags << "@#{lib.linklist(self)}" }
      xldflags << extinit_obj if need_exts_build?

      cflags = @cflags.dup
      xcflags = @xcflags.dup
      xcflags << "-DWASM_SETJMP_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_FIBER_STACK_BUFFER_SIZE=24576"
      xcflags << "-DWASM_SCAN_STACK_BUFFER_SIZE=24576"

      args << %Q(LDFLAGS=#{ldflags.join(" ")})
      args << %Q(XLDFLAGS=#{xldflags.join(" ")})
      args << %Q(CFLAGS=#{cflags.join(" ")})
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
