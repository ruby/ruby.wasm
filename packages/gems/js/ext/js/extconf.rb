require "mkmf"
$objs = %w[js-core.o witapi-core.o bindgen/legacy/rb-js-abi-host.o bindgen/legacy/rb-abi-guest.o]
create_makefile("js")
