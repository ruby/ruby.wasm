require "mkmf"
$objs = ["witapi-core.o", "bindgen/rb-abi-guest.o"]
find_executable("wit-bindgen")
create_makefile("witapi")
