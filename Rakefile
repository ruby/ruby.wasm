require "rake"
require "json"
require "open-uri"

BUILD_SOURCES = [
  {
    name: "head",
    type: "github",
    repo: "ruby/ruby",
    rev: "master",
  },
]

FULL_EXTS = "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor"

BUILD_PROFILES = {
  "minimal"    => { default_exts: "", user_exts: [] },
  "minimal-js" => { default_exts: "", user_exts: ["js", "witapi"] },
  "full"       => { default_exts: FULL_EXTS, user_exts: [] },
  "full-js"    => { default_exts: FULL_EXTS, user_exts: ["js", "witapi"] },
}

BUILDS = [
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-js" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-js" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "full" },
]

NPM_PACKAGES = [
  { name: "ruby-wasm-emscripten", build: "head-wasm32-unknown-emscripten-full" },
  { name: "ruby-wasm-wasi", build: "head-wasm32-unknown-wasi-full-js" },
]

WAPM_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasi-full" },
  { name: "irb", build: "head-wasm32-unknown-wasi-full" },
]

class BuildSource
  include Rake::FileUtilsExt

  def initialize(params, base_dir)
    @params = params
    @base_dir = base_dir
  end

  def src_dir
    "#{@base_dir}/build/src/#{@params[:name]}"
  end

  def fetch
    case @params[:type]
    when "github"
      tarball_url = "https://api.github.com/repos/#{@params[:repo]}/tarball/#{@params[:rev]}"
      mkdir_p src_dir
      sh "curl -L #{tarball_url} | tar xz --strip-components=1", chdir: src_dir
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
    "#{@params[:src]}-#{@params[:target]}-#{@params[:profile]}"
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

  def check_deps
    target = @params[:target]
    profile = BUILD_PROFILES[@params[:profile]]
    user_exts = profile[:user_exts]

    case target
    when "wasm32-unknown-wasi"
      check_envvar("WASI_SDK_PATH")
      if lib_wasi_vfs_a.nil?
        STDERR.puts "warning: vfs feature is not enabled due to no LIB_WASI_VFS_A"
      end
    when "wasm32-unknown-emscripten"
      check_executable("emcc")
    end

    if user_exts.include?("js") or user_exts.include?("witapi")
      check_executable("wit-bindgen")
    end
  end

  def configure_args(build_triple)
    target = @params[:target]
    profile = BUILD_PROFILES[@params[:profile]]
    default_exts = profile[:default_exts]
    user_exts = profile[:user_exts]

    ldflags = %w(-Xlinker -zstack-size=16777216)
    xldflags = []

    args = ["--host", target, "--build", build_triple]
    args << "--with-static-linked-ext"
    args << %Q(--with-ext="#{default_exts}")

    case target
    when "wasm32-unknown-wasi"
      xldflags << lib_wasi_vfs_a unless lib_wasi_vfs_a.nil?
    when "wasm32-unknown-emscripten"
      ldflags.concat(%w(-s MODULARIZE=1))
      args.concat(%w(CC=emcc LD=emcc AR=emar RANLIB=emranlib))
    else
      raise "unknown target: #{target}"
    end

    (user_exts || []).each do |lib|
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

  base_dir = Dir.pwd

  build_srcs = {}
  BUILD_SOURCES.each do |src|
    build_srcs[src[:name]] = BuildSource.new(src, Dir.pwd)
  end

  build_srcs.each do |name, source|
    directory source.src_dir do
      source.fetch
    end
  end

  BUILDS.each do |params|
    source = build_srcs[params[:src]]
    build = BuildPlan.new(params, Dir.pwd)

    directory build.dest_dir

    directory build.build_dir => [source.src_dir] do
      # FIXME: It fails to make libencs in cross-compiling and
      # out-of-tree mysteriously.
      # It seems libencs target in exts.mk doesn't pass MINIRUBY to enc.mk,
      # and it's only used under the condition.
      mkdir_p File.dirname(build.build_dir)
      cp_r source.src_dir, build.build_dir
    end

    task "#{build.name}-configure", [:reconfigure] => [build.build_dir] do |t, args|
      args.with_defaults(:reconfigure => false)
      build.check_deps

      sh "./autogen.sh", chdir: build.build_dir
      if !File.exist?("#{build.build_dir}/Makefile") || args[:reconfigure]
        args = build.configure_args(RbConfig::CONFIG["host"])
        sh "./configure #{args.join(" ")}", chdir: build.build_dir
      end
    end

    desc "Build #{build.name}"
    task build.name => ["#{build.name}-configure", "#{build.name}-libs", build.dest_dir] do
      artifact = "rubies/ruby-#{build.name}.tar.gz"
      next if File.exist?(artifact)
      sh "make install DESTDIR=#{build.dest_dir}", chdir: build.build_dir
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
        make_cmd = %Q(make -C "#{base_dir}/ext/#{lib}" #{make_args.join(" ")} OBJDIR=#{objdir} obj)
        sh make_cmd
      end
      mkdir_p File.dirname(build.extinit_obj)
      sh %Q(ruby #{base_dir}/ext/extinit.c.erb #{libs.join(" ")} | #{cc} -c -x c - -o #{build.extinit_obj})
    end
  end
end

namespace :npm do
  NPM_PACKAGES.each do |pkg|
    desc "Build npm package #{pkg[:name]}"
    task pkg[:name] => ["build:#{pkg[:build]}"] do
      base_dir = Dir.pwd
      pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"
      sh "npm ci", chdir: pkg_dir
      sh "./build-package.sh #{base_dir}/rubies/#{pkg[:build]}", chdir: pkg_dir
    end
  end

  desc "Build all npm packages"
  multitask :all => NPM_PACKAGES.map { |pkg| pkg[:name] }
end

namespace :wapm do
  WAPM_PACKAGES.each do |pkg|
    pkg_dir = "#{Dir.pwd}/packages/wapm-packages/#{pkg[:name]}"

    desc "Build wapm package #{pkg[:name]}"
    task "#{pkg[:name]}-build" => ["build:#{pkg[:build]}"] do
      base_dir = Dir.pwd
      sh "./build-package.sh #{base_dir}/rubies/#{pkg[:build]}", chdir: pkg_dir
    end

    desc "Publish wapm package #{pkg[:name]}"
    task "#{pkg[:name]}-publish" => ["#{pkg[:name]}-build"] do
      check_executable("wapm")
      sh "wapm publish", chdir: pkg_dir
    end
  end
end

RELASE_ARTIFACTS = [
  # ruby builds
  "ruby-head-wasm32-unknown-emscripten-full",
  "ruby-head-wasm32-unknown-emscripten-minimal",
  "ruby-head-wasm32-unknown-wasi-full",
  "ruby-head-wasm32-unknown-wasi-full-js",
  "ruby-head-wasm32-unknown-wasi-minimal",
  "ruby-head-wasm32-unknown-wasi-minimal-js",
]

def release_note
  output = <<EOS
| channel | source |
|:-------:|:------:|
EOS

  BUILD_SOURCES.each do |source|
    case source[:type]
    when "github"
      url = "https://api.github.com/repos/#{source[:repo]}/commits/#{source[:rev]}"
      commit = OpenURI.open_uri(url) do |f|
        JSON.load(f.read)
      end
      output += "| #{source[:name]} | [`#{source[:repo]}@#{commit["sha"]}`](https://github.com/ruby/ruby/tree/#{commit["sha"]}) |\n"
    else
      raise "unknown source type: #{source[:type]}"
    end
  end
  output
end

desc "Fetch artifacts of a run of GitHub Actions"
task :fetch_artifacts, [:run_id] do |t, args|
  check_executable("gh")

  artifacts = JSON.load(%x(gh api repos/{owner}/{repo}/actions/runs/#{args[:run_id]}/artifacts))
  artifacts = artifacts["artifacts"].filter { RELASE_ARTIFACTS.include?(_1["name"]) }
  mkdir_p "release"
  Dir.chdir("release") do
    artifacts.each do |artifact|
      url = artifact["archive_download_url"]
      sh "gh api #{url} > #{artifact["name"]}.zip"
      mkdir_p artifact["name"]
      sh "unzip #{artifact["name"]}.zip -d #{artifact["name"]}"
      rm "#{artifact["name"]}.zip"
    end
  end
end

desc "Publish artifacts as a GitHub Release"
task :publish, [:tag, :opts] do |t, args|
  args.with_defaults(:opts => "")
  check_executable("gh")

  files = RELASE_ARTIFACTS.flat_map do |artifact|
    Dir.glob("release/#{artifact}/*")
  end
  File.open("release/note.md", "w") do |f|
    f.print release_note
  end
  sh %Q(gh release create #{args[:tag]} #{args[:opts]} --title #{args[:tag]} --notes-file release/note.md --prerelease #{files.join(" ")})
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
