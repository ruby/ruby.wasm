require "mkmf"

MakeMakefile::RbConfig ||= RbConfig
unless MakeMakefile::RbConfig::CONFIG["platform"] =~ /wasm/
  $stderr.puts "This extension is only for WebAssembly. Creating a dummy Makefile."
  create_makefile("js")
  return
end

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

component_type_obj = "$(srcdir)/bindgen/ext_component_type.o"

unless $static
  # When building shared library, we need to link the component type object
  # to the shared library instead of the main ruby executable.
  $libs << component_type_obj
end

create_makefile("js") do |mk|
  mk << "EXTRA_OBJS = #{component_type_obj}\n" if use_component_model
  mk
end
