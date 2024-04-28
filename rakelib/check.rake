namespace :check do
  legacy_wit_bindgen = RubyWasm::WitBindgen.new(build_dir: "build", revision: "251e84b89121751f79ac268629e9285082b2596d")
  wit_bindgen = RubyWasm::WitBindgen.new(build_dir: "build")
  task :install_wit_bindgen do
    legacy_wit_bindgen.install
    wit_bindgen.install
  end
  task legacy_bindgen_c: :install_wit_bindgen do
    wits = [
      %w[packages/gems/js/ext/js/bindgen/legacy/rb-abi-guest.wit --export],
      %w[packages/gems/js/ext/js/bindgen/legacy/rb-js-abi-host.wit --import]
    ]
    wits.each do |wit|
      path, mode = wit
      sh "#{legacy_wit_bindgen.bin_path} guest c #{mode} #{path} --out-dir #{File.dirname(path)}"
    end
  end

  task legacy_bindgen_js: :install_wit_bindgen do
    sh *[
         legacy_wit_bindgen.bin_path,
         "host",
         "js",
         "--import",
         "packages/gems/js/ext/js/bindgen/legacy/rb-abi-guest.wit",
         "--export",
         "packages/gems/js/ext/js/bindgen/legacy/rb-js-abi-host.wit",
         "--out-dir",
         "packages/npm-packages/ruby-wasm-wasi/src/bindgen/legacy"
       ]
  end

  task bindgen_c: :install_wit_bindgen do
    js_pkg_dir = "packages/gems/js"
    sh(
      wit_bindgen.bin_path,
      "c",
      File.join(js_pkg_dir, "wit"),
      "--out-dir",
      File.join(js_pkg_dir, "ext", "js", "bindgen")
    )
  end

  desc "Check wit-bindgen'ed sources are up-to-date"
  task bindgen: %i[bindgen_c legacy_bindgen_c legacy_bindgen_js]

  task :type do
    sh "bundle exec steep check"
  end
end
