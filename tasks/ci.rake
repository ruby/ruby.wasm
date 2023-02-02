def latest_build_sources
  BUILD_SOURCES
    .map do |name, src|
      case src[:type]
      when "github"
        url = "https://api.github.com/repos/#{src[:repo]}/commits/#{src[:rev]}"
        revision = OpenURI.open_uri(url) { |f| JSON.load(f.read) }
        [name, revision["sha"]]
      else
        raise "#{src[:type]} is not supported to pin source revision"
      end
    end
    .to_h
end

NPM_RELEASE_ARTIFACTS = %w[
  npm-ruby-head-wasm-emscripten
  npm-ruby-head-wasm-wasi
  npm-ruby-3_2-wasm-wasi
]
RELASE_ARTIFACTS =
  BUILD_TASKS.map do |build|
    File.basename(build.crossruby.artifact, ".tar.gz")
  end + NPM_RELEASE_ARTIFACTS

def release_note
  output = <<EOS
| channel | source |
|:-------:|:------:|
EOS

  BUILD_SOURCES.each do |name, source|
    case source[:type]
    when "github"
      url =
        "https://api.github.com/repos/#{source[:repo]}/commits/#{source[:rev]}"
      commit = OpenURI.open_uri(url) { |f| JSON.load(f.read) }
      output +=
        "| #{name} | [`#{source[:repo]}@#{commit["sha"]}`](https://github.com/ruby/ruby/tree/#{commit["sha"]}) |\n"
    else
      raise "unknown source type: #{source[:type]}"
    end
  end
  output
end

def sh_or_warn(*cmd)
  sh *cmd do |ok, status|
    unless ok
      warn "Command failed with status (#{status.exitstatus}): #{cmd.join ""}"
    end
  end
end

namespace :ci do
  task :rake_task_matrix do
    require "pathname"
    ruby_cache_keys = {}
    BUILD_TASKS.each { |build| ruby_cache_keys[build.name] = build.hexdigest }
    entries =
      BUILD_TASKS.map do |build|
        {
          task: "build:#{build.name}",
          artifact:
            Pathname
              .new(build.crossruby.artifact)
              .relative_path_from(LIB_ROOT)
              .to_s,
          artifact_name: File.basename(build.crossruby.artifact, ".tar.gz"),
          builder: build.target,
          rubies_cache_key: ruby_cache_keys[build.name]
        }
      end
    entries +=
      NPM_PACKAGES.map do |pkg|
        entry = {
          task: "npm:#{pkg[:name]}",
          prerelease: "npm:configure_prerelease",
          artifact: "packages/npm-packages/#{pkg[:name]}/#{pkg[:name]}-*.tgz",
          artifact_name: "npm-#{pkg[:name]}",
          builder: pkg[:target],
          rubies_cache_key: ruby_cache_keys[pkg[:build]]
        }
        # Run tests only if the package has 'test' script
        package_json =
          JSON.parse(
            File.read("packages/npm-packages/#{pkg[:name]}/package.json")
          )
        if package_json["scripts"] && package_json["scripts"]["test"]
          entry[:test] = "npm:#{pkg[:name]}-check"
        end
        entry
      end
    entries +=
      WAPM_PACKAGES.map do |pkg|
        {
          task: "wapm:#{pkg[:name]}-build",
          artifact: "packages/wapm-packages/#{pkg[:name]}/dist",
          artifact_name: "wapm-#{pkg[:name]}",
          builder: "wasm32-unknown-wasi",
          rubies_cache_key: ruby_cache_keys[pkg[:build]]
        }
      end
    print JSON.generate(entries)
  end

  task :pin_build_manifest do
    content = JSON.generate({ ruby_revisions: latest_build_sources })
    File.write("build_manifest.json", content)
  end

  desc "Fetch artifacts of a run of GitHub Actions"
  task :fetch_artifacts, [:run_id] do |t, args|
    RubyWasm::Toolchain.check_executable("gh")
  
    artifacts =
      JSON.load(
        `gh api repos/{owner}/{repo}/actions/runs/#{args[:run_id]}/artifacts`
      )
    artifacts =
      artifacts["artifacts"].filter { RELASE_ARTIFACTS.include?(_1["name"]) }
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
  
    nightly = /^\d{4}-\d{2}-\d{2}-.$/.match?(args[:tag])
    files =
      RELASE_ARTIFACTS.flat_map { |artifact| Dir.glob("release/#{artifact}/*") }
    File.open("release/note.md", "w") { |f| f.print release_note }
    NPM_RELEASE_ARTIFACTS.each do |artifact|
      tarball = Dir.glob("release/#{artifact}/*")
      next if tarball.empty?
      tarball = tarball[0]
      # tolerate failure as a case that has already been released
      npm_tag = nightly ? "next" : "latest"
      sh_or_warn %Q(npm publish --tag #{npm_tag} #{tarball})
    end
    sh %Q(gh release create #{args[:tag]} --title #{args[:tag]} --notes-file release/note.md #{nightly ? "--prerelease" : ""} #{files.join(" ")})
  end
end
