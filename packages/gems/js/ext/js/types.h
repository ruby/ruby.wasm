#ifndef RUBY_WASM_JS_TYPES_H
#define RUBY_WASM_JS_TYPES_H

#ifdef JS_ENABLE_COMPONENT_MODEL
# include "bindgen/ext.h"

typedef exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t         rb_abi_guest_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_own_rb_abi_value_t            rb_abi_guest_own_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t    rb_abi_guest_list_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_own_rb_iseq_t                 rb_abi_guest_rb_iseq_t;
typedef exports_ruby_js_ruby_runtime_rb_id_t                       rb_abi_guest_rb_id_t;
typedef exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t rb_abi_guest_tuple2_rb_abi_value_s32_t;

typedef ruby_js_js_runtime_borrow_js_abi_value_t      rb_js_abi_host_js_abi_value_t;
typedef ruby_js_js_runtime_own_js_abi_value_t         rb_js_abi_host_own_js_abi_value_t;
typedef ruby_js_js_runtime_js_abi_result_t            rb_js_abi_host_js_abi_result_t;
typedef ruby_js_js_runtime_list_borrow_js_abi_value_t rb_js_abi_host_list_js_abi_value_t;
typedef ruby_js_js_runtime_raw_integer_t               rb_js_abi_host_raw_integer_t;

typedef ext_string_t rb_abi_guest_string_t;
typedef ext_string_t rb_js_abi_host_string_t;
typedef ext_list_string_t rb_abi_guest_list_string_t;

# define rb_abi_guest_rb_abi_value_new(val) exports_ruby_js_ruby_runtime_rb_abi_value_new(val)
# define rb_abi_guest_rb_abi_value_get(val) (*(val))
# define rb_abi_guest_rb_iseq_new(val) exports_ruby_js_ruby_runtime_rb_iseq_new(val)
# define rb_js_abi_host_js_value_equal(lhs, rhs) ruby_js_js_runtime_js_value_equal(lhs, rhs)
# define rb_js_abi_host_reflect_apply(target, this, args, ret) ruby_js_js_runtime_reflect_apply(target, this, args, ret)
# define rb_js_abi_host_js_value_to_integer(value, ret) ruby_js_js_runtime_js_value_to_integer(value, ret)
#else
# include "bindgen/legacy/rb-abi-guest.h"
# include "bindgen/legacy/rb-js-abi-host.h"
typedef rb_abi_guest_rb_abi_value_t            rb_abi_guest_own_rb_abi_value_t;
typedef rb_js_abi_host_js_abi_value_t          rb_js_abi_host_own_js_abi_value_t;
#endif

#endif // RUBY_WASM_JS_TYPES_H
