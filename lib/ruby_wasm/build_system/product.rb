require "rake"
require_relative "product/product"
require_relative "product/baseruby"
require_relative "product/zlib"
require_relative "product/libyaml"

module RubyWasm
  class ConfigureTask < BuildProduct
    def define_task(build, source)
      task "#{build.name}-configure", [:reconfigure] => [build.build_dir, source.src_dir, source.configure_file] + build.dep_tasks do |t, args|
        args.with_defaults(:reconfigure => false)
        build.check_deps

        if !File.exist?("#{build.build_dir}/Makefile") || args[:reconfigure]
          args = build.configure_args(RbConfig::CONFIG["host"])
          sh "#{source.configure_file} #{args.join(" ")}", chdir: build.build_dir
        end
        # NOTE: we need rbconfig.rb at configuration time to build user given extensions with mkmf
        sh "make rbconfig.rb", chdir: build.build_dir
      end
    end
  end

  class MakeTask < BuildProduct
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def define_task(build, source, configure)
      desc "Build #{build.name}"
      task build.name => [configure, "#{build.name}-libs", build.dest_dir] do
        artifact = "rubies/ruby-#{build.name}.tar.gz"
        next if File.exist?(artifact)
        sh "make install DESTDIR=#{build.dest_dir}", chdir: build.build_dir
        sh "tar cfz #{artifact} -C rubies #{build.name}"
      end
    end
  end

  class ExtBuildProduct < BuildProduct
    attr_reader :params, :base_dir

    def initialize(params, base_dir)
      @params = params
      @base_dir = base_dir
    end

    def define_task(build, source, toolchain, configure)
      task "#{build.name}-libs" => [configure] do
        make_args = []
        make_args << "CC=#{toolchain.cc}"
        make_args << "RANLIB=#{toolchain.ranlib}"
        make_args << "LD=#{toolchain.ld}"
        make_args << "AR=#{toolchain.ar}"

        make_args << %Q(RUBY_INCLUDE_FLAGS="-I#{source.src_dir}/include -I#{build.build_dir}/.ext/include/wasm32-wasi")
        libs = BUILD_PROFILES[params[:profile]][:user_exts]
        libs.each do |lib|
          objdir = "#{build.ext_build_dir}/#{lib}"
          FileUtils.mkdir_p objdir
          srcdir = "#{base_dir}/ext/#{lib}"
          extconf_args = [
            "--disable=gems",
            # HACK: top_srcdir is required to find ruby headers
            "-e", %Q('$top_srcdir="#{source.src_dir}"'),
            # HACK: extout is required to find config.h
            "-e", %Q('$extout="#{build.build_dir}/.ext"'),
            # HACK: force static ext build by imitating extmk
            "-e", %Q('$static = true; trace_var(:$static) {|v| $static = true }'),
            # HACK: $0 should be extconf.rb path due to mkmf source file detection
            # and we want to insert some hacks before it. But -e and $0 cannot be
            # used together, so we rewrite $0 in -e.
            "-e", %Q('$0="#{srcdir}/extconf.rb"'),
            "-e", %Q('require_relative "#{srcdir}/extconf.rb"'),
            "-I#{build.build_dir}",
          ]
          sh "#{build.baseruby_path} #{extconf_args.join(" ")}", chdir: objdir
          make_cmd = %Q(make -C "#{objdir}" #{make_args.join(" ")} static)
          sh make_cmd
          # A ext can provide link args by link.filelist. It contains only built archive file by default.
          unless File.exist?("#{objdir}/link.filelist")
            File.write("#{objdir}/link.filelist", Dir.glob("#{objdir}/*.a").join("\n"))
          end
        end
        mkdir_p File.dirname(build.extinit_obj)
        sh %Q(ruby #{base_dir}/ext/extinit.c.erb #{libs.join(" ")} | #{toolchain.cc} -c -x c - -o #{build.extinit_obj})
      end
    end
  end
end
