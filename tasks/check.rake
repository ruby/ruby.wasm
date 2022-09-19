namespace :check do
  desc "Check wit-bindgen'ed sources are up-to-date"
  task :bindgen do
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
end