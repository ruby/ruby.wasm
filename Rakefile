require "rake"
require "json"
require "open-uri"

$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require "bundler/gem_tasks"
require "ruby_wasm/rake_task"
require "ruby_wasm/packager"
require "ruby_wasm/cli"

BUILD_SOURCES = %w[3.3 3.2 head]
BUILD_PROFILES = %w[full minimal]

BUILDS =
  BUILD_SOURCES
    .product(BUILD_PROFILES)
    .map { |src, profile| [src, "wasm32-unknown-wasip1", profile] } +
    BUILD_SOURCES.map { |src| [src, "wasm32-unknown-emscripten", "full"] }

NPM_PACKAGES = [
  {
    name: "ruby-head-wasm-emscripten",
    ruby_version: "head",
    gemfile: nil,
    target: "wasm32-unknown-emscripten"
  },
  {
    name: "ruby-head-wasm-wasi",
    ruby_version: "head",
    gemfile: "packages/npm-packages/ruby-wasm-wasi/Gemfile",
    target: "wasm32-unknown-wasip1"
  },
  {
    name: "ruby-3.3-wasm-wasi",
    ruby_version: "3.3",
    gemfile: "packages/npm-packages/ruby-wasm-wasi/Gemfile",
    target: "wasm32-unknown-wasip1"
  },
  {
    name: "ruby-3.2-wasm-wasi",
    ruby_version: "3.2",
    gemfile: "packages/npm-packages/ruby-wasm-wasi/Gemfile",
    target: "wasm32-unknown-wasip1"
  },
  { name: "ruby-wasm-wasi", target: "wasm32-unknown-wasip1" }
]

STANDALONE_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasip1-full" },
  { name: "irb", build: "head-wasm32-unknown-wasip1-full" }
]

LIB_ROOT = File.dirname(__FILE__)

TOOLCHAINS = {}
BUILDS
  .map { |_, target, _| target }
  .uniq
  .each do |target|
    build_dir = File.join(LIB_ROOT, "build")
    toolchain = RubyWasm::Toolchain.get(target, build_dir)
    TOOLCHAINS[toolchain.name] = toolchain
  end

class BuildTask < Struct.new(:name, :target, :build_command)
  def ruby_cache_key
    return @key if @key
    require "open3"
    cmd = build_command + ["--print-ruby-cache-key"]
    stdout, status = Open3.capture2(*cmd)
    unless status.success?
      raise "Command failed with status (#{status.exitstatus}): #{cmd.join ""}"
    end
    require "json"
    @key = JSON.parse(stdout)
  end

  def hexdigest
    ruby_cache_key["hexdigest"]
  end
  def artifact
    ruby_cache_key["artifact"]
  end
end

namespace :build do
  BUILD_TASKS =
    BUILDS.map do |src, target, profile|
      name = "#{src}-#{target}-#{profile}"

      build_command = [
        "exe/rbwasm",
        "build",
        "--ruby-version",
        src,
        "--target",
        target,
        "--build-profile",
        profile,
        "--disable-gems",
        "-o",
        "/dev/null"
      ]
      desc "Cross-build Ruby for #{target}"
      task name do
        sh *build_command
      end
      namespace name do
        task :remake do
          sh *build_command, "--remake"
        end
        task :reconfigure do
          sh *build_command, "--reconfigure"
        end
        task :clean do
          sh *build_command, "--clean"
        end
      end

      BuildTask.new(name, target, build_command)
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
