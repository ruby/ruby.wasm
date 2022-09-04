require "mkmf"
$objs = ["witapi-core.o", "bindgen/rb-abi-guest.o"]
create_makefile("witapi")
