require "rake"
require "json"
require "open-uri"

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "ruby_wasm/rake_task"

Dir.glob("tasks/**.rake").each { |f| import f }

BUILD_SOURCES = {
  "head" => {
    type: "github",
    repo: "ruby/ruby",
    rev: "master",
    patches: Dir["./patches/*.patch"].map { |p| File.expand_path(p) }
  },
  "3_2" => {
    type: "github",
    repo: "ruby/ruby",
    rev: "v3_2_0"
  }
}

# Respect revisions specified in build_manifest.json, which is usually generated on GitHub Actions.
if File.exist?("build_manifest.json")
  begin
    manifest = JSON.parse(File.read("build_manifest.json"))
    manifest["ruby_revisions"].each do |name, rev|
      BUILD_SOURCES[name][:rev] = rev
    end
  rescue StandardError
    $stderr.puts "Failed to load build_manifest.json"
  end
end

FULL_EXTS =
  "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl"

BUILD_PROFILES = {
  "minimal" => {
    debug: false,
    default_exts: "",
    user_exts: []
  },
  "minimal-debug" => {
    debug: true,
    default_exts: "",
    user_exts: []
  },
  "minimal-js" => {
    debug: false,
    default_exts: "",
    user_exts: %w[js witapi]
  },
  "minimal-js-debug" => {
    debug: true,
    default_exts: "",
    user_exts: %w[js witapi]
  },
  "full" => {
    debug: false,
    default_exts: FULL_EXTS,
    user_exts: []
  },
  "full-debug" => {
    debug: true,
    default_exts: FULL_EXTS,
    user_exts: []
  },
  "full-js" => {
    debug: false,
    default_exts: FULL_EXTS,
    user_exts: %w[js witapi]
  },
  "full-js-debug" => {
    debug: true,
    default_exts: FULL_EXTS,
    user_exts: %w[js witapi]
  }
}

BUILDS =
  BUILD_SOURCES.keys.flat_map do |src|
    %w[wasm32-unknown-wasi wasm32-unknown-emscripten].flat_map do |target|
      BUILD_PROFILES
        .keys
        .select do |profile_name|
          if target == "wasm32-unknown-emscripten"
            profile = BUILD_PROFILES[profile_name]
            user_exts = profile[:user_exts]
            # Skip builds with JS extensions or debug mode for Emscripten
            # because JS extensions have incompatible import/export entries
            # and debug mode is rarely used for Emscripten.
            next(
              !(
                user_exts.include?("witapi") || user_exts.include?("js") ||
                  profile[:debug]
              )
            )
          end
          next true
        end
        .map { |profile| { src: src, target: target, profile: profile } }
    end
  end

NPM_PACKAGES = [
  {
    name: "ruby-head-wasm-emscripten",
    build: "head-wasm32-unknown-emscripten-full",
    target: "wasm32-unknown-emscripten"
  },
  {
    name: "ruby-head-wasm-wasi",
    build: "head-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  },
  {
    name: "ruby-3_2-wasm-wasi",
    build: "3_2-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  }
]

STANDALONE_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasi-full" },
  { name: "irb", build: "head-wasm32-unknown-wasi-full" }
]

LIB_ROOT = File.dirname(__FILE__)

TOOLCHAINS = {}

namespace :build do
  BUILD_TASKS =
    BUILDS.map do |params|
      name = "#{params[:src]}-#{params[:target]}-#{params[:profile]}"
      source = BUILD_SOURCES[params[:src]].merge(name: params[:src])
      profile = BUILD_PROFILES[params[:profile]]
      options = {
        src: source,
        target: params[:target],
        default_exts: profile[:default_exts]
      }
      debug = profile[:debug]
      RubyWasm::BuildTask.new(name, **options) do |t|
        if debug
          t.crossruby.debugflags = %w[-g]
          t.crossruby.wasmoptflags = %w[-O3 -g]
          t.crossruby.ldflags = %w[
            -Xlinker
            --stack-first
            -Xlinker
            -z
            -Xlinker
            stack-size=16777216
          ]
        else
          t.crossruby.debugflags = %w[-g0]
          t.crossruby.ldflags = %w[-Xlinker -zstack-size=16777216]
        end

        toolchain = t.toolchain
        t.crossruby.user_exts =
          profile[:user_exts].map do |ext|
            srcdir = File.join(LIB_ROOT, "ext", ext)
            RubyWasm::CrossRubyExtProduct.new(srcdir, toolchain)
          end
        unless TOOLCHAINS.key? toolchain.name
          TOOLCHAINS[toolchain.name] = toolchain
        end
      end
    end

  desc "Clean build directories"
  task :clean do
    rm_rf "./build"
    rm_rf "./rubies"
  end

  desc "Download prebuilt Ruby"
  task :download_prebuilt, :tag do |t, args|
    require "ruby_wasm/build_system/downloader"

    release =
      if args[:tag]
        url =
          "https://api.github.com/repos/ruby/ruby.wasm/releases/tags/#{args[:tag]}"
        OpenURI.open_uri(url) { |f| JSON.load(f.read) }
      else
        url = "https://api.github.com/repos/ruby/ruby.wasm/releases?per_page=1"
        OpenURI.open_uri(url) { |f| JSON.load(f.read)[0] }
      end

    puts "Downloading from release \"#{release["tag_name"]}\""

    rubies_dir = "./rubies"
    downloader = RubyWasm::Downloader.new
    rm_rf rubies_dir
    mkdir_p rubies_dir

    assets = release["assets"].select { |a| a["name"].end_with? ".tar.gz" }
    assets.each_with_index do |asset, i|
      url = asset["browser_download_url"]
      tarball = File.join("rubies", asset["name"])
      rm_rf tarball, verbose: false
      downloader.download(
        url,
        tarball,
        "[%2d/%2d] Downloading #{File.basename(url)}" % [i + 1, assets.size]
      )
      sh "tar xzf #{tarball} -C ./rubies"
    end
  end
end
