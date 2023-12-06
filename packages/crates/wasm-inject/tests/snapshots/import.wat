(module
  (type (;0;) (func))
  (type (;1;) (func (result i32)))
  (type (;2;) (func (result i32 i64)))
  (type (;3;) (func (param i32)))
  (type (;4;) (func (param i32) (result i32)))
  (type (;5;) (func (param i32) (result i64)))
  (type (;6;) (func (param i32) (result f32)))
  (type (;7;) (func (param i32) (result f64)))
  (type (;8;) (func (param i32 i32)))
  (type (;9;) (func (param i32 i32) (result i32)))
  (type (;10;) (func (param i32 i32 i32)))
  (type (;11;) (func (param i32 i64)))
  (type (;12;) (func (param i32 i64) (result f32 f64)))
  (type (;13;) (func (param i64 i32)))
  (type (;14;) (func (param f32 i32)))
  (type (;15;) (func (param f64 i32)))
  (import "t" "empty" (func (;0;) (type 0)))
  (import "t" "p_i32" (func (;1;) (type 3)))
  (import "t" "p_i32_i64" (func (;2;) (type 11)))
  (import "t" "r_i32" (func (;3;) (type 1)))
  (import "t" "r_i32_i64" (func (;4;) (type 2)))
  (import "t" "p_i32_i64_r_f32_f64" (func (;5;) (type 12)))
  (func $my-mod.init_add_import_func (;6;) (type 3) (param i32)
    (local i32 i32)
    i32.const 0
    i32.const 2
    call $cabi_realloc
    local.set 0
    local.get 0
    i32.const 0
    i32.add
    i32.const 116
    i32.store16 align=1
    i32.const 0
    i32.const 6
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i32.const 1953525093
    i32.store align=1
    local.get 1
    i32.const 4
    i32.add
    i32.const 121
    i32.store16 align=1
    local.get 0
    local.get 1
    i32.const 1
    call $my-mod.add_import_func
    i32.const 0
    i32.const 6
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i32.const 862543728
    i32.store align=1
    local.get 1
    i32.const 4
    i32.add
    i32.const 50
    i32.store16 align=1
    local.get 0
    local.get 1
    i32.const 2
    call $my-mod.add_import_func
    i32.const 0
    i32.const 10
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i64.const 3920769619818274672
    i64.store align=1
    local.get 1
    i32.const 8
    i32.add
    i32.const 52
    i32.store16 align=1
    local.get 0
    local.get 1
    i32.const 3
    call $my-mod.add_import_func
    i32.const 0
    i32.const 6
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i32.const 862543730
    i32.store align=1
    local.get 1
    i32.const 4
    i32.add
    i32.const 50
    i32.store16 align=1
    local.get 0
    local.get 1
    i32.const 4
    call $my-mod.add_import_func
    i32.const 0
    i32.const 10
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i64.const 3920769619818274674
    i64.store align=1
    local.get 1
    i32.const 8
    i32.add
    i32.const 52
    i32.store16 align=1
    local.get 0
    local.get 1
    i32.const 5
    call $my-mod.add_import_func
    i32.const 0
    i32.const 20
    call $cabi_realloc
    local.set 1
    local.get 1
    i32.const 0
    i32.add
    i64.const 3920769619818274672
    i64.store align=1
    local.get 1
    i32.const 8
    i32.add
    i64.const 6859601697219698484
    i64.store align=1
    local.get 1
    i32.const 16
    i32.add
    i32.const 3421798
    i32.store align=1
    local.get 0
    local.get 1
    i32.const 6
    call $my-mod.add_import_func
  )
  (func (;7;) (type 3) (param i32)
    local.get 0
    call $my-mod.pop_i32
    local.get 0
    call $my-mod.pop_i64
    call 5
    local.get 0
    call $my-mod.push_f64
    local.get 0
    call $my-mod.push_f32
  )
  (func (;8;) (type 3) (param i32)
    local.get 0
    call $my-mod.pop_i32
    local.get 0
    call $my-mod.pop_i64
    call 2
  )
  (func (;9;) (type 3) (param i32)
    call 4
    local.get 0
    call $my-mod.push_i64
    local.get 0
    call $my-mod.push_i32
  )
  (func (;10;) (type 3) (param i32)
    local.get 0
    call $my-mod.pop_i32
    call 1
  )
  (func (;11;) (type 3) (param i32)
    call 3
    local.get 0
    call $my-mod.push_i32
  )
  (func $my-mod.call_export_func (;12;) (type 8) (param i32 i32)
    unreachable
  )
  (func $my-mod.add_import_func (;13;) (type 10) (param i32 i32 i32)
    unreachable
  )
  (func $my-mod.init_context (;14;) (type 1) (result i32)
    unreachable
  )
  (func $my-mod.destroy_context (;15;) (type 3) (param i32)
    unreachable
  )
  (func $my-mod.push_i32 (;16;) (type 8) (param i32 i32)
    unreachable
  )
  (func $my-mod.push_i64 (;17;) (type 13) (param i64 i32)
    unreachable
  )
  (func $my-mod.push_f32 (;18;) (type 14) (param f32 i32)
    unreachable
  )
  (func $my-mod.push_f64 (;19;) (type 15) (param f64 i32)
    unreachable
  )
  (func $my-mod.pop_i32 (;20;) (type 4) (param i32) (result i32)
    unreachable
  )
  (func $my-mod.pop_i64 (;21;) (type 5) (param i32) (result i64)
    unreachable
  )
  (func $my-mod.pop_f32 (;22;) (type 6) (param i32) (result f32)
    unreachable
  )
  (func $my-mod.pop_f64 (;23;) (type 7) (param i32) (result f64)
    unreachable
  )
  (func $cabi_realloc (;24;) (type 9) (param i32 i32) (result i32)
    unreachable
  )
  (func $cabi_free (;25;) (type 3) (param i32)
    unreachable
  )
  (func (;26;) (type 3) (param i32)
    call 0
  )
  (table (;0;) 7 funcref)
  (memory (;0;) 1)
  (export "my-mod.imports_table" (table 0))
  (export "memory" (memory 0))
  (export "my-mod.call_export_func" (func $my-mod.call_export_func))
  (export "my-mod.add_import_func" (func $my-mod.add_import_func))
  (export "my-mod.init_context" (func $my-mod.init_context))
  (export "my-mod.destroy_context" (func $my-mod.destroy_context))
  (export "my-mod.push_i32" (func $my-mod.push_i32))
  (export "my-mod.push_i64" (func $my-mod.push_i64))
  (export "my-mod.push_f32" (func $my-mod.push_f32))
  (export "my-mod.push_f64" (func $my-mod.push_f64))
  (export "my-mod.pop_i32" (func $my-mod.pop_i32))
  (export "my-mod.pop_i64" (func $my-mod.pop_i64))
  (export "my-mod.pop_f32" (func $my-mod.pop_f32))
  (export "my-mod.pop_f64" (func $my-mod.pop_f64))
  (export "cabi_realloc" (func $cabi_realloc))
  (export "cabi_free" (func $cabi_free))
  (elem (;0;) (i32.const 0) func $my-mod.init_add_import_func 26 10 8 11 9 7)
  (@producers
    (processed-by "walrus" "0.20.3")
  )
)