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

def get_toolchain(target)
  case target
  when "wasm32-unknown-wasi"
    return RubyWasm::WASISDK.new
  when "wasm32-unknown-emscripten"
    return RubyWasm::Emscripten.new
  end
end

namespace :deps do
  ["wasm32-unknown-wasi", "wasm32-unknown-emscripten"].each do |target|
    toolchain = get_toolchain(target)
    install_dir = File.join(Dir.pwd, "/build/deps/#{target}/opt")
    RubyWasm::LibYAMLProduct.new(Dir.pwd, install_dir, target, toolchain).define_task
    RubyWasm::ZlibProduct.new(Dir.pwd, install_dir, target, toolchain).define_task
  end
end

namespace :build do

  base_dir = Dir.pwd

  build_srcs = {}
  BUILD_SOURCES.each do |src|
    source = RubyWasm::BuildSource.new(src, Dir.pwd)
    build_srcs[src[:name]] = source
    source.define_task
  end

  build_srcs.each do |name, source|
    RubyWasm::BaseRubyProduct.new(name, base_dir, source).define_task
  end

  BUILDS.each do |params|
    source = build_srcs[params[:src]]
    toolchain = get_toolchain params[:target]
    user_exts = BUILD_PROFILES[params[:profile]][:user_exts].map do |ext|
      RubyWasm::CrossRubyExtProduct.new(ext, toolchain)
    end
    build_params = RubyWasm::BuildParams.new(
      **params.merge(BUILD_PROFILES[params[:profile]]).merge(src: source, user_exts: user_exts)
    )
    product = RubyWasm::CrossRubyProduct.new(build_params, base_dir, source, toolchain)
    product.define_task
  end
end
