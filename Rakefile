require "rake"
require_relative "ci/configure_args"

namespace :deps do
  task "check-wasm32-unknown-wasi" do
    check_executable("wit-bindgen")
    check_envvar("WASI_SDK_PATH")
  end
  task "check-wasm32-unknown-emscripten" do
    check_executable("emcc")
  end
end

BUILD_SOURCES = [
  {
    name: "pr-1726",
    type: "github",
    repo: "kateinoigakukun/ruby",
    rev: "337b9df76e2850292c31983d2c992f768fc4cc5e",
  },
]

BUILD_PARAMS = [
  { target: "wasm32-unknown-wasi", flavor: "minimal", libs: [] },
  { target: "wasm32-unknown-wasi", flavor: "minimal-js", libs: ["js", "witapi"] },
  { target: "wasm32-unknown-wasi", flavor: "full", libs: [] },
  { target: "wasm32-unknown-wasi", flavor: "full-js", libs: ["js", "witapi"] },
  { target: "wasm32-unknown-emscripten", flavor: "minimal", libs: [] },
  { target: "wasm32-unknown-emscripten", flavor: "full", libs: [] },
]

PACKAGES = [
  { name: "ruby-wasm-emscripten", build: "pr-1726-wasm32-unknown-emscripten-full" },
  { name: "ruby-wasm-wasi", build: "pr-1726-wasm32-unknown-wasi-full-js" },
]

class BuildPlan
  def initialize(source, params, base_dir)
    @source = source
    @params = params
    @base_dir = base_dir
  end

  def name
    "#{@source[:name]}-#{@params[:target]}-#{@params[:flavor]}"
  end

  def build_dir
    "#{@base_dir}/build/build/#{name}"
  end

  def ext_build_dir
    "#{@base_dir}/build/ext-build/#{name}"
  end

  def dest_dir
    "#{@base_dir}/rubies/#{name}"
  end

  def extinit_obj
    "#{ext_build_dir}/extinit.o"
  end

  def configure_args(build_triple)
    target = @params[:target]
    flavor = @params[:flavor]
    libs = @params[:libs]

    ldflags = %w(-Xlinker -zstack-size=16777216)
    xldflags = []

    args = ["--host", target, "--build", build_triple]
    args << "--with-static-linked-ext"

    case flavor
    when /^minimal/
      args << %Q(--with-ext="")
    when /^full/
      args << %Q(--with-ext="bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor")
    else
      raise "unknown flavor: #{flavor}"
    end

    case target
    when "wasm32-unknown-wasi"
    when "wasm32-unknown-emscripten"
      ldflags.concat(%w(-s MODULARIZE=1))
      args.concat(%w(CC=emcc LD=emcc AR=emar RANLIB=emranlib))
    else
      raise "unknown flavor: #{flavor}"
    end

    (libs || []).each do |lib|
      xldflags << "@#{ext_build_dir}/#{lib}/link.filelist"
    end
    xldflags << extinit_obj

    args << %Q(LDFLAGS="#{ldflags.join(" ")}")
    args << %Q(XLDFLAGS="#{xldflags.join(" ")}")
    args << %Q(debugflags="-g0")
    args << "--disable-install-doc"
    args
  end
end

namespace :build do
  BUILD_SOURCES.each do |source|
    base_dir = Dir.pwd
    src_dir = "#{base_dir}/build/src/#{source[:name]}"

    directory src_dir do
      case source[:type]
      when "github"
        tarball_url = "https://api.github.com/repos/#{source[:repo]}/tarball/#{source[:rev]}"
        mkdir_p src_dir
        sh "curl -L #{tarball_url} | tar xz --strip-components=1", chdir: src_dir
      else
        raise "unknown source type: #{source[:type]}"
      end
    end
    build_plans = BUILD_PARAMS.map do |params|
      build = BuildPlan.new(source, params, Dir.pwd)

      directory build.dest_dir

      directory build.build_dir => [src_dir] do
        # FIXME: It fails to make libencs in cross-compiling and
        # out-of-tree mysteriously.
        # It seems libencs target in exts.mk doesn't pass MINIRUBY to enc.mk,
        # and it's only used under the condition.
        mkdir_p File.dirname(build.build_dir)
        cp_r src_dir, build.build_dir
      end

      task "#{build.name}-configure", [:reconfigure] => ["deps:check-#{params[:target]}", build.build_dir] do |t, args|
        args.with_defaults(:reconfigure => false)

        sh "./autogen.sh", chdir: build.build_dir
        if !File.exist?("#{build.build_dir}/Makefile") || args[:reconfigure]
          args = build.configure_args(RbConfig::CONFIG["host"])
          sh "./configure #{args.join(" ")}", chdir: build.build_dir
        end
      end

      desc "Build #{build.name}"
      task build.name => ["#{build.name}-configure", "#{build.name}-libs", build.dest_dir] do
        sh "make install DESTDIR=#{build.dest_dir}", chdir: build.build_dir
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
        make_args << %Q(RUBY_INCLUDE_FLAGS="-I#{src_dir}/include -I#{build.build_dir}/.ext/include/wasm32-wasi")
        make_args << %Q(OBJDIR=#{build.ext_build_dir})
        params[:libs].each do |lib|
          make_cmd = %Q(make -C "#{base_dir}/ext/#{lib}" #{make_args.join(" ")} OBJDIR=#{build.ext_build_dir}/#{lib} obj)
          sh make_cmd
        end
        mkdir_p File.dirname(build.extinit_obj)
        sh %Q(ruby #{base_dir}/ext/extinit.c.erb #{params[:libs].join(" ")} | #{cc} -c -x c - -o #{build.extinit_obj})
      end

      build
    end

    desc "Build #{source[:name]}"
    multitask source[:name] => build_plans.map { |build| build.name }
  end
end

namespace :pkg do
  PACKAGES.each do |pkg|
    desc "Build #{pkg[:name]}"
    task pkg[:name] => ["build:#{pkg[:build]}"] do
      base_dir = Dir.pwd
      pkg_dir = "#{Dir.pwd}/packages/#{pkg[:name]}"
      sh "npm ci", chdir: pkg_dir
      sh "./build-package.sh #{base_dir}/rubies/#{pkg[:build]}", chdir: pkg_dir
    end
  end

  desc "Build all packages"
  multitask :all => PACKAGES.map { |pkg| pkg[:name] }
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
