def latest_build_sources
  BUILD_SOURCES.map do |name, src|
    case src[:type]
    when "github"
      url = "https://api.github.com/repos/#{src[:repo]}/commits/#{src[:rev]}"
      revision = OpenURI.open_uri(url) { |f| JSON.load(f.read) }
      [name, revision["sha"]]
    else
      raise "#{src[:type]} is not supported to pin source revision"
    end
  end.to_h
end
namespace :ci do
  task :rake_task_matrix do
    require "pathname"
    ruby_cache_keys = {}
    BUILD_TASKS.each do |build|
      ruby_cache_keys[build.name] = build.hexdigest
    end
    entries = BUILD_TASKS.map do |build|
      {
        task: "build:#{build.name}",
        artifact: Pathname.new(build.crossruby.artifact).relative_path_from(LIB_ROOT).to_s,
        artifact_name: File.basename(build.crossruby.artifact, ".tar.gz"),
        builder: build.target,
        rubies_cache_key: ruby_cache_keys[build.name],
      }
    end
    entries += NPM_PACKAGES.map do |pkg|
      entry = {
        task: "npm:#{pkg[:name]}",
        prerelease: "npm:configure_prerelease",
        artifact: "packages/npm-packages/#{pkg[:name]}/#{pkg[:name]}-*.tgz",
        artifact_name: "npm-#{pkg[:name]}",
        builder: pkg[:target],
        rubies_cache_key: ruby_cache_keys[pkg[:build]],
      }
      # Run tests only if the package has 'test' script
      package_json = JSON.parse(File.read("packages/npm-packages/#{pkg[:name]}/package.json"))
      if package_json["scripts"] && package_json["scripts"]["test"]
        entry[:test] = "npm:#{pkg[:name]}-check"
      end
      entry
    end
    entries += WAPM_PACKAGES.map do |pkg|
      {
        task: "wapm:#{pkg[:name]}-build",
        artifact: "packages/wapm-packages/#{pkg[:name]}/dist",
        artifact_name: "wapm-#{pkg[:name]}",
        builder: "wasm32-unknown-wasi",
        rubies_cache_key: ruby_cache_keys[pkg[:build]],
      }
    end
    print JSON.generate(entries)
  end

  task :pin_build_manifest do
    content = JSON.generate({ ruby_revisions: latest_build_sources })
    File.write("build_manifest.json", content)
  end
end
