require "mkmf"
$objs = ["js-core.o", "bindgen/rb-js-abi-host.o"]
raise "missing executable: wit-bindgen" unless find_executable("wit-bindgen")
create_makefile("js")
