require "mkmf"
$objs = %w[js-core.o witapi-core.o]

use_component_model = enable_config("component-model", false)
$stderr.print "Building with component model: "
$stderr.puts use_component_model ? "\e[1;32myes\e[0m" : "\e[1;31mno\e[0m"
if use_component_model
  $defs << "-DJS_ENABLE_COMPONENT_MODEL=1"
  $objs << "bindgen/ext.o"
else
  $objs << "bindgen/legacy/rb-js-abi-host.o"
  $objs << "bindgen/legacy/rb-abi-guest.o"
end
create_makefile("js") do |mk|
  mk << "EXTRA_OBJS = $(srcdir)/bindgen/ext_component_type.o\n" if use_component_model
  mk
end
