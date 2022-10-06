NPM_PACKAGES = [
  { name: "ruby-head-wasm-emscripten", build: "head-wasm32-unknown-emscripten-full" },
  { name: "ruby-head-wasm-wasi", build: "head-wasm32-unknown-wasi-full-js-debug" },
]

WAPM_PACKAGES = [
  { name: "ruby", build: "head-wasm32-unknown-wasi-full" },
  { name: "irb", build: "head-wasm32-unknown-wasi-full" },
]

namespace :npm do
  wasi_vfs = RubyWasm::WasiVfsProduct.new("build")
  wasi_vfs.define_task
  wasi_sdk = TOOLCHAINS["wasi-sdk"]
  tools = {
    "WASI_VFS_CLI" => wasi_vfs.cli_bin_path,
    "WASMOPT" => wasi_sdk.wasm_opt,
  }
  NPM_PACKAGES.each do |pkg|
    base_dir = Dir.pwd
    pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"

    desc "Build npm package #{pkg[:name]}"
    task pkg[:name] => ["build:#{pkg[:build]}", wasi_vfs.cli_install_task, wasi_sdk.binaryen_install_task] do
      sh "npm ci", chdir: pkg_dir
      sh tools, "#{pkg_dir}/build-package.sh #{base_dir}/rubies/#{pkg[:build]}"
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
      RubyWasm::Toolchain.check_executable("wapm")
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
  "ruby-head-wasm32-unknown-wasi-full-debug",
  "ruby-head-wasm32-unknown-wasi-full-js",
  "ruby-head-wasm32-unknown-wasi-full-js-debug",
  "ruby-head-wasm32-unknown-wasi-minimal",
  "ruby-head-wasm32-unknown-wasi-minimal-debug",
  "ruby-head-wasm32-unknown-wasi-minimal-js",
  "ruby-head-wasm32-unknown-wasi-minimal-js-debug",
] + NPM_RELEASE_ARTIFACTS

def release_note
  output = <<EOS
| channel | source |
|:-------:|:------:|
EOS

  BUILD_SOURCES.each do |name, source|
    case source[:type]
    when "github"
      url = "https://api.github.com/repos/#{source[:repo]}/commits/#{source[:rev]}"
      commit = OpenURI.open_uri(url) do |f|
        JSON.load(f.read)
      end
      output += "| #{name} | [`#{source[:repo]}@#{commit["sha"]}`](https://github.com/ruby/ruby/tree/#{commit["sha"]}) |\n"
    else
      raise "unknown source type: #{source[:type]}"
    end
  end
  output
end

desc "Fetch artifacts of a run of GitHub Actions"
task :fetch_artifacts, [:run_id] do |t, args|
  RubyWasm::Toolchain.check_executable("gh")

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
  RubyWasm::Toolchain.check_executable("gh")

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

def sh_or_warn(*cmd)
  sh *cmd do |ok, status|
    unless ok
      warn "Command failed with status (#{status.exitstatus}): #{cmd.join ""}"
    end
  end
end
