require "rake"
require "json"
require "open-uri"

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "ruby_wasm/rake_task"

Dir.glob("tasks/**.rake").each { |f| import f }

BUILD_SOURCES = ["3.3", "3.2", "head"]
BUILD_PROFILES = ["full", "minimal"]

BUILDS = BUILD_SOURCES.product(BUILD_PROFILES).map do |src, profile|
  [src, "wasm32-unknown-wasi", profile]
end + BUILD_SOURCES.map do |src|
  [src, "wasm32-unknown-emscripten", "full"]
end

NPM_PACKAGES = [
  {
    name: "ruby-head-wasm-emscripten",
    build: "head-wasm32-unknown-emscripten-full",
    target: "wasm32-unknown-emscripten"
  },
  {
    name: "ruby-wasm-wasi",
    build: "head-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  },
  {
    name: "ruby-head-wasm-wasi",
    build: "head-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  },
  {
    name: "ruby-3.3-wasm-wasi",
    build: "3.3-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  },
  {
    name: "ruby-3.2-wasm-wasi",
    build: "3.2-wasm32-unknown-wasi-full-js-debug",
    target: "wasm32-unknown-wasi"
  }
]

STANDALONE_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasi-full" },
  { name: "irb", build: "head-wasm32-unknown-wasi-full" }
]

LIB_ROOT = File.dirname(__FILE__)

TOOLCHAINS = {}
BUILDS.map { |_, target, _| target }.uniq.each do |target|
  toolchain = RubyWasm::Toolchain.get(target)
  TOOLCHAINS[toolchain.name] = toolchain
end

namespace :build do
  BUILD_TASKS =
    BUILDS.map do |src, target, profile|
      name = "#{src}-#{target}-#{profile}"

      desc "Cross-build Ruby for #{@target}"
      task name do
        sh *["exe/rbwasm", "build", "--ruby-version", src, "--target", target, "--build-profile", profile, "-o", "/dev/null"]
      end
    end

  desc "Clean build directories"
  task :clean do
    rm_rf "./build"
    rm_rf "./rubies"
  end

  desc "Download prebuilt Ruby"
  task :download_prebuilt, :tag do |t, args|
    require "ruby_wasm/build/downloader"

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
