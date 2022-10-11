require "mkmf"
$objs = %w[js-core.o bindgen/rb-js-abi-host.o]
create_makefile("js")
