def bump_version_npm_package(package, version)
  require "json"
  pkg_dir = "#{Dir.pwd}/packages/npm-packages/#{package}"
  pkg_json = "#{pkg_dir}/package.json"
  package = JSON.parse(File.read(pkg_json))
  old_version = package["version"]
  pkg_name = package["name"]
  package["version"] = version
  File.write(pkg_json, JSON.pretty_generate(package) + "\n")

  # Update package-lock.json
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

def bump_version_rb(version_rb, version)
  version_rb_content = File.read(version_rb)
  version_rb_content.gsub!(/VERSION = ".+"/, "VERSION = \"#{version}\"")
  File.write(version_rb, version_rb_content)
end

task :bump_version, %i[version] do |t, args|
  version = args[:version] or raise "version is required"
  bump_version_rb("lib/ruby_wasm/version.rb", version)
  bump_version_rb("packages/gems/js/lib/js/version.rb", version)
  NPM_PACKAGES.each { |pkg| bump_version_npm_package(pkg[:name], version) }
  # Update ./package-lock.json
  sh "npm install"
  # Update Gemfile.lock
  sh "BUNDLE_GEMFILE=packages/npm-packages/ruby-wasm-wasi/Gemfile bundle install"
end

def bump_dev_version_rb(version_rb)
  version_rb_content = File.read(version_rb)
  version_rb_content.sub!(/VERSION = "(.+)"$/) do
    dev_version = $1.end_with?(".dev") ? $1 : $1 + ".dev"
    "VERSION = \"#{dev_version}\""
  end
  File.write(version_rb, version_rb_content)
end

task :bump_dev_version do
  bump_dev_version_rb("lib/ruby_wasm/version.rb")
  bump_dev_version_rb("packages/gems/js/lib/js/version.rb")
end
