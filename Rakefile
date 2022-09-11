require "rake"
require "json"
require "open-uri"

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "ruby_wasm/build_system"

Dir.glob("rake/**.rake").each { |f| import f }

BUILD_SOURCES = [
  {
    name: "head",
    type: "github",
    repo: "ruby/ruby",
    rev: "master",
    patches: [],
  },
]

FULL_EXTS = "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib"

BUILD_PROFILES = {
  "minimal"          => { debug: false, default_exts: "", user_exts: [] },
  "minimal-debug"    => { debug: true,  default_exts: "", user_exts: [] },
  "minimal-js"       => { debug: false, default_exts: "", user_exts: ["js", "witapi"] },
  "minimal-js-debug" => { debug: true,  default_exts: "", user_exts: ["js", "witapi"] },
  "full"             => { debug: false, default_exts: FULL_EXTS, user_exts: [] },
  "full-debug"       => { debug: true,  default_exts: FULL_EXTS, user_exts: [] },
  "full-js"          => { debug: false, default_exts: FULL_EXTS, user_exts: ["js", "witapi"] },
  "full-js-debug"    => { debug: true,  default_exts: FULL_EXTS, user_exts: ["js", "witapi"] },
}

BUILDS = [
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-debug" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-js" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-js-debug" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-debug" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-js" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-js-debug" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "full" },
]

NPM_PACKAGES = [
  { name: "ruby-head-wasm-emscripten", build: "head-wasm32-unknown-emscripten-full" },
  { name: "ruby-head-wasm-wasi", build: "head-wasm32-unknown-wasi-full-js-debug" },
]

WAPM_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasi-full" },
  { name: "irb", build: "head-wasm32-unknown-wasi-full" },
]

namespace :deps do
  ["wasm32-unknown-wasi", "wasm32-unknown-emscripten"].each do |target|
    install_dir = File.join(Dir.pwd, "/build/deps/#{target}/opt")
    libyaml_version = "0.2.5"
    desc "build libyaml #{libyaml_version} for #{target}"
    task "libyaml-#{target}" do
      next if Dir.exist?("#{install_dir}/libyaml")

      build_dir = File.join(Dir.pwd, "/build/deps/#{target}/yaml-#{libyaml_version}")
      mkdir_p File.dirname(build_dir)
      rm_rf build_dir
      sh "curl -L https://github.com/yaml/libyaml/releases/download/#{libyaml_version}/yaml-#{libyaml_version}.tar.gz | tar xz", chdir: File.dirname(build_dir)

      # obtain the latest config.guess and config.sub for Emscripten and WASI triple support
      sh "curl -o #{build_dir}/config/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'"
      sh "curl -o #{build_dir}/config/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'"

      configure_args = []
      case target
      when "wasm32-unknown-wasi"
        configure_args.concat(%W(--host wasm32-wasi CC=#{ENV["WASI_SDK_PATH"]}/bin/clang RANLIB=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ranlib LD=#{ENV["WASI_SDK_PATH"]}/bin/clang AR=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ar))
      when "wasm32-unknown-emscripten"
        configure_args.concat(%W(--host wasm32-emscripten CC=emcc RANLIB=emranlib LD=emcc AR=emar))
      else
        raise "unknown target: #{target}"
      end
      sh "./configure #{configure_args.join(" ")}", chdir: build_dir
      sh "make install DESTDIR=#{install_dir}/libyaml", chdir: build_dir
    end

    zlib_version = "1.2.12"
    desc "build zlib #{zlib_version} for #{target}"
    task "zlib-#{target}" do
      next if Dir.exist?("#{install_dir}/zlib")

      build_dir = File.join(Dir.pwd, "/build/deps/#{target}/zlib-#{zlib_version}")
      mkdir_p File.dirname(build_dir)
      rm_rf build_dir

      sh "curl -L https://zlib.net/zlib-#{zlib_version}.tar.gz | tar xz", chdir: File.dirname(build_dir)

      configure_args = []
      case target
      when "wasm32-unknown-wasi"
        configure_args.concat(%W(CC=#{ENV["WASI_SDK_PATH"]}/bin/clang RANLIB=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ranlib AR=#{ENV["WASI_SDK_PATH"]}/bin/llvm-ar))
      when "wasm32-unknown-emscripten"
        configure_args.concat(%W(CC=emcc RANLIB=emranlib AR=emar))
      else
        raise "unknown target: #{target}"
      end
      sh "#{configure_args.join(" ")} ./configure --prefix=#{install_dir}/zlib --static", chdir: build_dir
      sh "make install", chdir: build_dir
    end
  end
end

namespace :build do

  base_dir = Dir.pwd

  build_srcs = {}
  BUILD_SOURCES.each do |src|
    build_srcs[src[:name]] = RubyWasm::BuildSource.new(src, Dir.pwd)
  end

  build_srcs.each do |name, source|
    directory source.src_dir do
      source.fetch
    end
    file source.configure_file => [source.src_dir] do
      sh "./autogen.sh", chdir: source.src_dir
    end

    baseruby_install_dir = File.join(Dir.pwd, "/build/deps/#{RbConfig::CONFIG["host"]}/opt/baseruby-#{name}")
    baseruby_build_dir   = File.join(Dir.pwd, "/build/deps/#{RbConfig::CONFIG["host"]}/baseruby-#{name}")

    directory baseruby_build_dir

    desc "build baseruby #{name}"
    task "baseruby-#{name}" => [source.src_dir, source.configure_file, baseruby_build_dir] do
      next if Dir.exist?(baseruby_install_dir)
      sh "#{source.configure_file} --prefix=#{baseruby_install_dir} --disable-install-doc", chdir: baseruby_build_dir
      sh "make install", chdir: baseruby_build_dir
    end
  end

  BUILDS.each do |params|
    source = build_srcs[params[:src]]
    build_params = RubyWasm::BuildParams.new(
      **params.merge(BUILD_PROFILES[params[:profile]]).merge(src: source)
    )
    build = RubyWasm::BuildPlan.new(build_params, Dir.pwd)

    directory build.dest_dir
    directory build.build_dir

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

    task "#{build.name}-install" => ["#{build.name}-configure", "#{build.name}-libs", build.dest_dir] do
      next if File.exist?("#{build.dest_dir}-install")
      sh "make install DESTDIR=#{build.dest_dir}-install", chdir: build.build_dir
    end

    desc "Build #{build.name}"
    task build.name => ["#{build.name}-install", build.dest_dir] do
      artifact = "rubies/ruby-#{build.name}.tar.gz"
      next if File.exist?(artifact)
      rm_rf build.dest_dir
      cp_r "#{build.dest_dir}-install", build.dest_dir
      libs = BUILD_PROFILES[params[:profile]][:user_exts]
      ruby_api_version = `#{build.baseruby_path} -e 'print RbConfig::CONFIG["ruby_version"]'`
      libs.each do |lib|
        next unless File.exist?("ext/#{lib}/lib")
        cp_r(File.join(base_dir, "ext/#{lib}/lib/."), File.join(build.dest_dir, "usr/local/lib/ruby/#{ruby_api_version}"))
      end
      sh "tar cfz #{artifact} -C rubies #{build.name}"
    end

    task "#{build.name}-libs" => ["#{build.name}-configure"] do
      make_args = []
      case params[:target]
      when "wasm32-unknown-wasi"
        wasi_sdk_path = ENV["WASI_SDK_PATH"]
        cc = "#{wasi_sdk_path}/bin/clang"
        make_args << "CC=#{cc}"
        make_args << "LD=#{wasi_sdk_path}/bin/wasm-ld"
        make_args << "AR=#{wasi_sdk_path}/bin/llvm-ar"
        make_args << "RANLIB=#{wasi_sdk_path}/bin/llvm-ranlib"
      when "wasm32-unknown-emscripten"
        cc = "emcc"
        make_args << "CC=#{cc}"
        make_args << "LD=emcc"
        make_args << "AR=emar"
        make_args << "RANLIB=emranlib"
      else
        raise "unknown target: #{params[:target]}"
      end
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
      sh %Q(ruby #{base_dir}/ext/extinit.c.erb #{libs.join(" ")} | #{cc} -c -x c - -o #{build.extinit_obj})
    end
  end
end

def check_executable(command)
  (ENV["PATH"] || "").split(File::PATH_SEPARATOR).each do |path_dir|
    bin_path = File.join(path_dir, command)
    return bin_path if File.executable?(bin_path)
  end
  raise "missing executable: #{command}"
end

def check_envvar(name)
  if ENV[name].nil?
    raise "missing environment variable: #{name}"
  end
end

def lib_wasi_vfs_a
  ENV["LIB_WASI_VFS_A"]
end

def sh_or_warn(*cmd)
  sh *cmd do |ok, status|
    unless ok
      warn "Command failed with status (#{status.exitstatus}): #{cmd.join ""}"
    end
  end
end
