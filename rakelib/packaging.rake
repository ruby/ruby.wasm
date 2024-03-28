wasi_vfs = RubyWasm::WasiVfsProduct.new(File.join(Dir.pwd, "build"))
wasi_sdk = TOOLCHAINS["wasi-sdk"]
tools = {
  "WASI_VFS_CLI" => File.expand_path(File.join(__dir__, "..", "exe", "rbwasm")),
  "WASMOPT" => wasi_sdk.wasm_opt
}

def npm_pkg_build_command(pkg)
  # Skip if the package does not require building ruby
  return nil unless pkg[:ruby_version] && pkg[:target]
  [
    "bundle",
    "exec",
    "rbwasm",
    "build",
    "--ruby-version",
    pkg[:ruby_version],
    "--target",
    pkg[:target],
    "--build-profile",
    "full"
  ]
end

def npm_pkg_rubies_cache_key(pkg)
  build_command = npm_pkg_build_command(pkg)
  return nil unless build_command
  require "open3"
  cmd = build_command + ["--print-ruby-cache-key"]
  stdout, status = Open3.capture2(*cmd)
  unless status.success?
    raise "Command failed with status (#{status.exitstatus}): #{cmd.join ""}"
  end
  require "json"
  JSON.parse(stdout)["hexdigest"]
end

namespace :npm do
  NPM_PACKAGES.each do |pkg|
    base_dir = Dir.pwd
    pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"

    namespace pkg[:name] do
      desc "Build ruby for npm package #{pkg[:name]}"
      task "ruby" do
        build_command = npm_pkg_build_command(pkg)
        # Skip if the package does not require building ruby
        next unless build_command

        env = {
          # Share ./build and ./rubies in the same workspace
          "RUBY_WASM_ROOT" => base_dir
        }
        cwd = nil
        if gemfile_path = pkg[:gemfile]
          cwd = File.dirname(gemfile_path)
        else
          # Explicitly disable rubygems integration since Bundler finds
          # Gemfile in the repo root directory.
          build_command.push "--disable-gems"
        end
        dist_dir = File.join(pkg_dir, "dist")
        mkdir_p dist_dir
        if pkg[:target].start_with?("wasm32-unknown-wasi")
          Dir.chdir(cwd || base_dir) do
            sh env,
               *build_command,
               "--no-stdlib",
               "-o",
               File.join(dist_dir, "ruby.wasm")
            sh env,
               *build_command,
               "-o",
               File.join(dist_dir, "ruby.debug+stdlib.wasm")
          end
          sh wasi_sdk.wasm_opt,
             "--strip-debug",
             File.join(dist_dir, "ruby.wasm"),
             "-o",
             File.join(dist_dir, "ruby.wasm")
          sh wasi_sdk.wasm_opt,
             "--strip-debug",
             File.join(dist_dir, "ruby.debug+stdlib.wasm"),
             "-o",
             File.join(dist_dir, "ruby+stdlib.wasm")
        elsif pkg[:target] == "wasm32-unknown-emscripten"
          Dir.chdir(cwd || base_dir) do
            sh env, *build_command, "-o", "/dev/null"
          end
        end
      end

      desc "Build npm package #{pkg[:name]}"
      task "build" => ["ruby"] do
        sh tools, "npm run build", chdir: pkg_dir
      end

      desc "Check npm package #{pkg[:name]}"
      task "check" do
        sh "npm test", chdir: pkg_dir
      end
    end

    desc "Make tarball for npm package #{pkg[:name]}"
    task pkg[:name] do
      wasi_sdk.install_binaryen
      Rake::Task["npm:#{pkg[:name]}:build"].invoke
      sh "npm pack", chdir: pkg_dir
    end
  end

  desc "Configure for pre-release"
  task :configure_prerelease, [:prerel] do |t, args|
    require "json"
    prerel = args[:prerel]
    new_pkgs = {}
    NPM_PACKAGES.each do |pkg|
      pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"
      pkg_json = "#{pkg_dir}/package.json"
      package = JSON.parse(File.read(pkg_json))

      version = package["version"] + "-#{prerel}"
      new_pkgs[package["name"]] = version
      sh *["npm", "pkg", "set", "version=#{version}"], chdir: pkg_dir
    end

    NPM_PACKAGES.each do |pkg|
      pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{pkg[:name]}"
      pkg_json = "#{pkg_dir}/package.json"
      package = JSON.parse(File.read(pkg_json))
      (package["dependencies"] || []).each do |dep, _|
        next unless new_pkgs[dep]
        sh *["npm", "pkg", "set", "dependencies.#{dep}=#{new_pkgs[dep]}"],
           chdir: pkg_dir
      end
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
      wasi_sdk.install_binaryen
      base_dir = Dir.pwd
      sh tools,
         "./build-package.sh #{base_dir}/rubies/ruby-#{pkg[:build]}",
         chdir: pkg_dir
    end
  end
end
