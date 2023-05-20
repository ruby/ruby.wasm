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

    namespace pkg[:name] do
      desc "Build npm package #{pkg[:name]}"
      task "build" => ["build:#{pkg[:build]}"] do
        sh tools, "npm run build", chdir: pkg_dir
      end

      desc "Check npm package #{pkg[:name]}"
      task "check" do
        sh "npm test", chdir: pkg_dir
      end
    end

    desc "Make tarball for npm package #{pkg[:name]}"
    task pkg[:name] do
      wasi_vfs.install_cli
      wasi_sdk.install_binaryen
      Rake::Task["npm:#{pkg[:name]}:build"].invoke
      sh "npm pack", chdir: pkg_dir
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
  multitask all: NPM_PACKAGES.map { |pkg| pkg[:name] }
end

namespace :standalone do
  STANDALONE_PACKAGES.each do |pkg|
    pkg_dir = "#{Dir.pwd}/packages/standalone/#{pkg[:name]}"

    desc "Build standalone package #{pkg[:name]}"
    task "#{pkg[:name]}" => ["build:#{pkg[:build]}"] do
      wasi_vfs.install_cli
      wasi_sdk.install_binaryen
      base_dir = Dir.pwd
      sh tools,
         "./build-package.sh #{base_dir}/rubies/#{pkg[:build]}",
         chdir: pkg_dir
    end
  end
end
