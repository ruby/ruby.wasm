require "rake"
require "json"
require "open-uri"

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "ruby_wasm/build_system"

Dir.glob("tasks/**.rake").each { |f| import f }

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
    RubyWasm::LibYAMLTask.new(Dir.pwd, install_dir, target).define_task
    RubyWasm::ZlibTask.new(Dir.pwd, install_dir, target).define_task
  end
end

namespace :build do

  base_dir = Dir.pwd

  build_srcs = {}
  BUILD_SOURCES.each do |src|
    build_srcs[src[:name]] = RubyWasm::BuildSource.new(src, Dir.pwd)
  end

  build_srcs.each do |name, source|
    RubyWasm::BaseRubyTask.new(name, base_dir).define_task source
  end

  BUILDS.each do |params|
    source = build_srcs[params[:src]]
    build_params = RubyWasm::BuildParams.new(
      **params.merge(BUILD_PROFILES[params[:profile]]).merge(src: source)
    )
    build = RubyWasm::BuildPlan.new(build_params, Dir.pwd)

    directory build.dest_dir
    directory build.build_dir

    configure = RubyWasm::ConfigureTask.new.define_task build, source
    make = RubyWasm::MakeTask.new.define_task build, source, configure
    ext_build = RubyWasm::ExtBuildProduct.new(params, base_dir).define_task build, source, configure
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
