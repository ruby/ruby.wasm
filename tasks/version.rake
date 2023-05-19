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


task :bump_version, %i[version] do |t, args|
  version = args[:version] or raise "version is required"
  NPM_PACKAGES.each do |pkg|
    bump_version_npm_package(pkg[:name], version)
  end
  # Update ./package-lock.json
  sh "npm install"
end
