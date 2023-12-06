.globl  ruby.c10zrt.imports_table
ruby.c10zrt.imports_table:
  .tabletype ruby.c10zrt.imports_table, funcref
.export_name ruby.c10zrt.imports_table, ruby.c10zrt.imports_table

.globl   ruby_c10zrt_invoke_import
.type    ruby_c10zrt_invoke_import, @function
ruby_c10zrt_invoke_import:
  .functype ruby_c10zrt_invoke_import (i32, i32) -> ()
  local.get 1
  local.get 0
  call_indirect ruby.c10zrt.imports_table, (i32) -> ()
  end_function
