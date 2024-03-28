def latest_build_sources
  BUILD_SOURCES
    .filter_map do |name|
      src = RubyWasm::CLI.build_source_aliases(LIB_ROOT)[name]
      case src[:type]
      when "github"
        url = "repos/#{src[:repo]}/commits/#{src[:rev]}"
        revision = JSON.parse(`gh api #{url}`)
        [name, revision["sha"]]
      when "tarball"
        nil
      else
        raise "#{src[:type]} is not supported to pin source revision"
      end
    end
    .to_h
end

def release_note
  output = <<EOS
| channel | source |
|:-------:|:------:|
EOS

  BUILD_SOURCES.each do |name|
    source = RubyWasm::CLI.build_source_aliases(LIB_ROOT)[name]
    case source[:type]
    when "github"
      output +=
        "| #{name} | [`#{source[:repo]}@#{source[:rev]}`](https://github.com/ruby/ruby/tree/#{source[:rev]}) |\n"
    when "tarball"
      output += "| #{name} | #{source[:url]} |\n"
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

def rake_task_matrix
  require "pathname"
  ruby_cache_keys = {}
  BUILD_TASKS.each { |build| ruby_cache_keys[build.name] = build.hexdigest }
  build_entries =
    BUILD_TASKS.map do |build|
      {
        task: "build:#{build.name}",
        artifact:
          Pathname.new(build.artifact).relative_path_from(LIB_ROOT).to_s,
        artifact_name: File.basename(build.artifact, ".tar.gz"),
        builder: build.target,
        rubies_cache_key: ruby_cache_keys[build.name]
      }
    end
  npm_entries =
    NPM_PACKAGES.map do |pkg|
      entry = {
        task: "npm:#{pkg[:name]}",
        prerelease: "npm:configure_prerelease",
        artifact: "packages/npm-packages/#{pkg[:name]}/#{pkg[:name]}-*.tgz",
        artifact_name: "npm-#{pkg[:name]}",
        builder: pkg[:target],
        rubies_cache_key: npm_pkg_rubies_cache_key(pkg)
      }
      # Run tests only if the package has 'test' script
      package_json =
        JSON.parse(
          File.read("packages/npm-packages/#{pkg[:name]}/package.json")
        )
      if package_json["scripts"] && package_json["scripts"]["test"]
        entry[:test] = "npm:#{pkg[:name]}:check"
      end
      entry
    end
  standalone_entries =
    STANDALONE_PACKAGES.map do |pkg|
      {
        task: "standalone:#{pkg[:name]}",
        artifact: "packages/standalone/#{pkg[:name]}/dist",
        artifact_name: "standalone-#{pkg[:name]}",
        builder: "wasm32-unknown-wasip1",
        rubies_cache_key: ruby_cache_keys[pkg[:build]]
      }
    end
  { build: build_entries, npm: npm_entries, standalone: standalone_entries }
end

namespace :ci do
  task :rake_task_matrix do
    print JSON.generate(rake_task_matrix.flat_map { |_, entries| entries })
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
    matrix = rake_task_matrix.flat_map { |_, entries| entries }
    release_artifacts = matrix.map { |entry| entry[:artifact_name] }
    artifacts =
      artifacts["artifacts"].filter { release_artifacts.include?(_1["name"]) }
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
    matrix = rake_task_matrix
    files =
      matrix
        .flat_map { |_, entries| entries }
        .map { |entry| "release/#{entry[:artifact_name]}/*" }
    File.open("release/note.md", "w") { |f| f.print release_note }
    matrix[:npm].each do |task|
      artifact = task[:artifact_name]
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
