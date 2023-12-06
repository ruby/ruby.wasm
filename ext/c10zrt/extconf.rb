require "mkmf"
$objs = %w[c10zrt.o c10zrt_core.o]
$CFLAGS += " -mreference-types"

create_makefile("c10zrt")
