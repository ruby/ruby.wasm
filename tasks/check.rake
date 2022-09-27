namespace :check do
  wit_bindgen = RubyWasm::WitBindgen.new(build_dir: "build")
  wit_bindgen.define_task
  task :bindgen_c => wit_bindgen.install_task do
    wits = [
      ["ext/witapi/bindgen/rb-abi-guest.wit", "--export"],
      ["ext/js/bindgen/rb-js-abi-host.wit", "--import"],
    ]
    wits.each do |wit|
      path, mode = wit
      sh "#{wit_bindgen.bin_path} guest c #{mode} #{path} --out-dir #{File.dirname(path)}"
    end
  end

  task :bindgen_js => wit_bindgen.install_task do
    sh *[
      wit_bindgen.bin_path, "host", "js",
      "--import", "ext/witapi/bindgen/rb-abi-guest.wit",
      "--export", "ext/js/bindgen/rb-js-abi-host.wit",
      "--out-dir", "packages/npm-packages/ruby-wasm-wasi/src/bindgen",
    ]
  end

  desc "Check wit-bindgen'ed sources are up-to-date"
  task :bindgen => [:bindgen_c, :bindgen_js]
end