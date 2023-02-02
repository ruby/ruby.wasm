wasi_vfs = RubyWasm::WasiVfsProduct.new(File.join(Dir.pwd, "build"))
wasi_sdk = TOOLCHAINS["wasi-sdk"]
tools = {
  "WASI_VFS_CLI" => wasi_vfs.cli_bin_path,
  "WASMOPT" => wasi_sdk.wasm_opt
}

namespace :npm do
  NPM_PACKAGES.each do |pkg|
    base_dir = Dir.pwd
    pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"

    desc "Build npm package #{pkg[:name]}"
    task pkg[:name] => ["build:#{pkg[:build]}"] do
      wasi_vfs.install_cli
      wasi_sdk.install_binaryen
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

  desc "Bump version"
  task :bump_version, %i[package version] do |t, args|
    require "json"
    package = args[:package] or raise "package name is required"
    version = args[:version] or raise "version is required"
    pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{package}"
    pkg_json = "#{pkg_dir}/package.json"
    package = JSON.parse(File.read(pkg_json))
    old_version = package["version"]
    pkg_name = package["name"]
    package["version"] = version
    File.write(pkg_json, JSON.pretty_generate(package) + "\n")

    # Update package-lock.json
    Dir.chdir(pkg_dir) { sh "npm install" }
    # Update README.md and other docs
    `git grep -l #{pkg_name}@#{old_version}`.split.each do |file|
      content = File.read(file)
      next_nightly = Date.today.strftime("%Y-%m-%d")
      content.gsub!(
        /#{pkg_name}@#{old_version}-\d{4}-\d{2}-\d{2}-a/,
        "#{pkg_name}@#{version}-#{next_nightly}-a"
      )
      content.gsub!(/#{pkg_name}@#{old_version}/, "#{pkg_name}@#{version}")
      File.write(file, content)
    end
  end

  desc "Build all npm packages"
  multitask all: NPM_PACKAGES.map { |pkg| pkg[:name] }
end

namespace :wapm do
  WAPM_PACKAGES.each do |pkg|
    pkg_dir = "#{Dir.pwd}/packages/wapm-packages/#{pkg[:name]}"

    desc "Build wapm package #{pkg[:name]}"
    task "#{pkg[:name]}-build" => ["build:#{pkg[:build]}"] do
      wasi_vfs.install_cli
      wasi_sdk.install_binaryen
      base_dir = Dir.pwd
      sh tools,
         "./build-package.sh #{base_dir}/rubies/#{pkg[:build]}",
         chdir: pkg_dir
    end

    desc "Publish wapm package #{pkg[:name]}"
    task "#{pkg[:name]}-publish" => ["#{pkg[:name]}-build"] do
      RubyWasm::Toolchain.check_executable("wapm")
      sh "wapm publish", chdir: pkg_dir
    end
  end
end
