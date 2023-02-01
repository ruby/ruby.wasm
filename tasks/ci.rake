namespace :ci do
  task :rake_task_matrix do
    require "pathname"
    entries = BUILD_TASKS.map do |build|
      {
        task: "build:#{build.name}",
        artifact: Pathname.new(build.crossruby.artifact).relative_path_from(LIB_ROOT).to_s,
        artifact_name: File.basename(build.crossruby.artifact, ".tar.gz"),
        builder: build.target,
      }
    end
    entries += NPM_PACKAGES.map do |pkg|
      {
        task: "npm:#{pkg[:name]}",
        test: "npm:#{pkg[:name]}-check",
        prerelease: "npm:configure_prerelease",
        artifact: "packages/npm-packages/#{pkg[:name]}/#{pkg[:name]}-*.tgz",
        artifact_name: "npm-#{pkg[:name]}",
        builder: pkg[:target],
      }
    end
    entries += WAPM_PACKAGES.map do |pkg|
      {
        task: "wapm:#{pkg[:name]}-build",
        artifact: "packages/wapm-packages/#{pkg[:name]}/dist",
        artifact_name: "wapm-#{pkg[:name]}",
        builder: "wasm32-unknown-wasi",
      }
    end
    print JSON.generate(entries)
  end
end
