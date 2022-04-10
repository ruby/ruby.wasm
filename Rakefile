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
  "minimal"          => { debug: false, default_exts: "", user_exts: [] },
  "minimal-js"       => { debug: false, default_exts: "", user_exts: ["js", "witapi"] },
  "minimal-js-debug" => { debug: true,  default_exts: "", user_exts: ["js", "witapi"] },
  "full"             => { debug: false, default_exts: FULL_EXTS, user_exts: [] },
  "full-js"          => { debug: false, default_exts: FULL_EXTS, user_exts: ["js", "witapi"] },
  "full-js-debug"    => { debug: true,  default_exts: FULL_EXTS, user_exts: ["js", "witapi"] },
}

BUILDS = [
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-js" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "minimal-js-debug" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-js" },
  { src: "head", target: "wasm32-unknown-wasi", profile: "full-js-debug" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "minimal" },
  { src: "head", target: "wasm32-unknown-emscripten", profile: "full" },
]

NPM_PACKAGES = [
  { name: "ruby-head-wasm-emscripten", build: "head-wasm32-unknown-emscripten-full" },
  { name: "ruby-head-wasm-wasi", build: "head-wasm32-unknown-wasi-full-js" },
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

  def configure_file
    "#{src_dir}/configure"
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

  def deps_install_dir
    "#{@base_dir}/build/deps/#{@params[:target]}/opt"
  end

  def dest_dir
    "#{@base_dir}/rubies/#{name}"
  end

  def extinit_obj
    "#{ext_build_dir}/extinit.o"
  end

  def dep_tasks
    return [] if @params[:profile] == "minimal"
    ["deps:libyaml-#{@params[:target]}"]
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

    ldflags = if profile[:debug]
      # use --stack-first to detect stack overflow easily
      %w(-Xlinker --stack-first -Xlinker -z -Xlinker stack-size=16777216)
    else
      %w(-Xlinker -zstack-size=16777216)
    end

    xldflags = []

    args = ["--host", target, "--build", build_triple]
    args << "--with-static-linked-ext"
    args << %Q(--with-ext="#{default_exts}")
    args << %Q(--with-libyaml-dir="#{deps_install_dir}/libyaml/usr/local")

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
    if profile[:debug]
      args << %Q(debugflags="-g")
      args << %Q(wasmoptflags="-O2 -g")
    else
      args << %Q(debugflags="-g0")
    end
    args << "--disable-install-doc"
    args
  end
end

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
    file source.configure_file => [source.src_dir] do
      sh "./autogen.sh", chdir: source.src_dir
    end
  end

  BUILDS.each do |params|
    source = build_srcs[params[:src]]
    build = BuildPlan.new(params, Dir.pwd)

    directory build.dest_dir
    directory build.build_dir

    task "#{build.name}-configure", [:reconfigure] => [build.build_dir, source.src_dir, source.configure_file] + build.dep_tasks do |t, args|
      args.with_defaults(:reconfigure => false)
      build.check_deps

      if !File.exist?("#{build.build_dir}/Makefile") || args[:reconfigure]
        args = build.configure_args(RbConfig::CONFIG["host"])
        sh "#{source.configure_file} #{args.join(" ")}", chdir: build.build_dir
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
    base_dir = Dir.pwd
    pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"

    desc "Build npm package #{pkg[:name]}"
    task pkg[:name] => ["build:#{pkg[:build]}"] do
      sh "npm ci", chdir: pkg_dir
      sh "#{pkg_dir}/build-package.sh #{base_dir}/rubies/#{pkg[:build]}"
      sh "npm pack", chdir: pkg_dir
    end

    desc "Check npm package #{pkg[:name]}"
    task "#{pkg[:name]}-check" do
      sh "npm test", chdir: pkg_dir
    end
  end

  desc "Configure for pre-release"
  task :configure_prerelease, [:prerel] do |t, args|
    require "json"
    prerel = args[:prerel]
    NPM_PACKAGES.each do |pkg|
      pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"
      pkg_json = "#{pkg_dir}/package.json"
      package = JSON.parse(File.read(pkg_json))
      package["version"] += "-#{prerel}"
      File.write(pkg_json, JSON.pretty_generate(package))
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

NPM_RELEASE_ARTIFACTS = [
  "npm-ruby-head-wasm-emscripten",
  "npm-ruby-head-wasm-wasi",
]
RELASE_ARTIFACTS = [
  # ruby builds
  "ruby-head-wasm32-unknown-emscripten-full",
  "ruby-head-wasm32-unknown-emscripten-minimal",
  "ruby-head-wasm32-unknown-wasi-full",
  "ruby-head-wasm32-unknown-wasi-full-js",
  "ruby-head-wasm32-unknown-wasi-minimal",
  "ruby-head-wasm32-unknown-wasi-minimal-js",
] + NPM_RELEASE_ARTIFACTS

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
task :publish, [:tag] do |t, args|
  check_executable("gh")

  files = RELASE_ARTIFACTS.flat_map do |artifact|
    Dir.glob("release/#{artifact}/*")
  end
  File.open("release/note.md", "w") do |f|
    f.print release_note
  end
  NPM_RELEASE_ARTIFACTS.each do |artifact|
    tarball = Dir.glob("release/#{artifact}/*")
    next if tarball.empty?
    tarball = tarball[0]
    # tolerate failure as a case that has already been released
    sh_or_warn %Q(npm publish --tag next #{tarball})
  end
  sh %Q(gh release create #{args[:tag]} --title #{args[:tag]} --notes-file release/note.md --prerelease #{files.join(" ")})
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
