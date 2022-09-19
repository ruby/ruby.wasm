namespace :check do
  task :bindgen_c do
    RubyWasm::Toolchain.check_executable("wit-bindgen")
    wits = [
      ["ext/witapi/bindgen/rb-abi-guest.wit", "--export"],
      ["ext/js/bindgen/rb-js-abi-host.wit", "--import"],
    ]
    wits.each do |wit|
      path, mode = wit
      sh "wit-bindgen c #{mode} #{path} --out-dir #{File.dirname(path)}"
    end
  end

  task :bindgen_js do
    sh *%w(
      wit-bindgen js
      --import ext/witapi/bindgen/rb-abi-guest.wit
      --export ext/js/bindgen/rb-js-abi-host.wit
      --out-dir packages/npm-packages/ruby-wasm-wasi/src/bindgen
    )
  end

  desc "Check wit-bindgen'ed sources are up-to-date"
  task :bindgen => [:bindgen_c, :bindgen_js]
end