#ifndef RUBY_WASM_JS_TYPES_H
#define RUBY_WASM_JS_TYPES_H

#ifdef JS_ENABLE_COMPONENT_MODEL
#  include "bindgen/ext.h"

typedef exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t
    rb_abi_guest_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_own_rb_abi_value_t
    rb_abi_guest_own_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t
    rb_abi_guest_list_rb_abi_value_t;
typedef exports_ruby_js_ruby_runtime_own_rb_iseq_t rb_abi_guest_rb_iseq_t;
typedef exports_ruby_js_ruby_runtime_rb_id_t rb_abi_guest_rb_id_t;
typedef exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t
    rb_abi_guest_tuple2_rb_abi_value_s32_t;

typedef ruby_js_js_runtime_borrow_js_abi_value_t rb_js_abi_host_js_abi_value_t;
typedef ruby_js_js_runtime_own_js_abi_value_t rb_js_abi_host_own_js_abi_value_t;
typedef ruby_js_js_runtime_js_abi_result_t rb_js_abi_host_js_abi_result_t;
typedef ruby_js_js_runtime_list_borrow_js_abi_value_t
    rb_js_abi_host_list_js_abi_value_t;
typedef ruby_js_js_runtime_raw_integer_t rb_js_abi_host_raw_integer_t;

typedef ext_string_t rb_abi_guest_string_t;
typedef ext_string_t rb_js_abi_host_string_t;
typedef ext_list_string_t rb_abi_guest_list_string_t;

#  define borrow_js_value(v) ruby_js_js_runtime_borrow_js_abi_value(v)

#  define rb_abi_guest_rb_abi_value_new(val)                                   \
    exports_ruby_js_ruby_runtime_rb_abi_value_new(val)
#  define rb_abi_guest_rb_abi_value_get(val) (*(val))
#  define rb_abi_guest_rb_iseq_new(val)                                        \
    exports_ruby_js_ruby_runtime_rb_iseq_new(val)
#  define rb_js_abi_host_js_value_equal(lhs, rhs)                              \
    ruby_js_js_runtime_js_value_equal(borrow_js_value(lhs),                    \
                                      borrow_js_value(rhs))
#  define rb_js_abi_host_reflect_apply(target, this, args, ret)                \
    ruby_js_js_runtime_reflect_apply(borrow_js_value(target),                  \
                                     borrow_js_value(this), args, ret)
#  define rb_js_abi_host_js_value_to_integer(value, ret)                       \
    ruby_js_js_runtime_js_value_to_integer(borrow_js_value(value), ret)
#  define rb_js_abi_host_export_js_value_to_host(value)                        \
    ruby_js_js_runtime_export_js_value_to_host(borrow_js_value(value))
#  define rb_js_abi_host_raw_integer_free(ptr)                                 \
    ruby_js_js_runtime_raw_integer_free(ptr)
#  define rb_js_abi_host_rb_object_to_js_rb_value(val)                         \
    ruby_js_js_runtime_rb_object_to_js_rb_value(val)
#  define rb_js_abi_host_int_to_js_number(val)                                 \
    ruby_js_js_runtime_int_to_js_number(val)
#  define rb_js_abi_host_float_to_js_number(val)                               \
    ruby_js_js_runtime_float_to_js_number(val)
#  define rb_js_abi_host_string_to_js_string(val)                              \
    ruby_js_js_runtime_string_to_js_string(val)
#  define rb_js_abi_host_bool_to_js_bool(val)                                  \
    ruby_js_js_runtime_bool_to_js_bool(val)
#  define rb_js_abi_host_import_js_value_from_host()                           \
    ruby_js_js_runtime_import_js_value_from_host()
#  define rb_js_abi_host_js_value_to_string(value, ret)                        \
    ruby_js_js_runtime_js_value_to_string(borrow_js_value(value), ret)
#  define rb_js_abi_host_js_value_typeof(value, ret)                           \
    ruby_js_js_runtime_js_value_typeof(borrow_js_value(value), ret)
#  define rb_js_abi_host_js_value_strictly_equal(lhs, rhs)                     \
    ruby_js_js_runtime_js_value_strictly_equal(borrow_js_value(lhs),           \
                                               borrow_js_value(rhs))
#  define rb_js_abi_host_reflect_get(target, key, ret)                         \
    ruby_js_js_runtime_reflect_get(borrow_js_value(target), key, ret)
#  define rb_js_abi_host_reflect_set(target, key, value, ret)                  \
    ruby_js_js_runtime_reflect_set(borrow_js_value(target), key,               \
                                   borrow_js_value(value), ret)
#  define rb_js_abi_host_global_this() ruby_js_js_runtime_global_this()
#  define rb_js_abi_host_instance_of(value, klass)                             \
    ruby_js_js_runtime_instance_of(borrow_js_value(value),                     \
                                   borrow_js_value(klass))
#  define rb_js_abi_host_is_js(value)                                          \
    ruby_js_js_runtime_is_js(borrow_js_value(value))
#  define rb_js_abi_host_eval_js(code, ret)                                    \
    ruby_js_js_runtime_eval_js(code, ret)

#  define rb_js_abi_host_js_abi_value_free(ptr)                                \
    ruby_js_js_runtime_js_abi_value_drop_own(*ptr)

#  define RB_JS_ABI_HOST_RAW_INTEGER_AS_FLOAT                                  \
    RUBY_JS_JS_RUNTIME_RAW_INTEGER_AS_FLOAT
#  define RB_JS_ABI_HOST_JS_ABI_RESULT_FAILURE                                 \
    RUBY_JS_JS_RUNTIME_JS_ABI_RESULT_FAILURE

void rb_abi_stage_rb_value_to_js(VALUE value);

#else
#  include "bindgen/legacy/rb-abi-guest.h"
#  include "bindgen/legacy/rb-js-abi-host.h"
typedef rb_abi_guest_rb_abi_value_t rb_abi_guest_own_rb_abi_value_t;
typedef rb_js_abi_host_js_abi_value_t rb_js_abi_host_own_js_abi_value_t;

#  define borrow_js_value(v) v

#  define rb_js_abi_host_js_abi_value_free(ptr)                                \
    rb_js_abi_host_js_abi_value_free(ptr)
#endif

#endif // RUBY_WASM_JS_TYPES_H
