require "mkmf"
$objs = ["js-core.o", "bindgen/rb-js-abi-host.o"]
find_executable("wit-bindgen")
create_makefile("js")
