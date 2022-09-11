require "mkmf"
$objs = ["witapi-core.o", "bindgen/rb-abi-guest.o"]
raise "missing executable: wit-bindgen" unless find_executable("wit-bindgen")
create_makefile("witapi")
