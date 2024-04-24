#ifndef __BINDINGS_RB_JS_ABI_HOST_H
#define __BINDINGS_RB_JS_ABI_HOST_H
#ifdef __cplusplus
extern "C"
{
  #endif
  
  #include <stdint.h>
  #include <stdbool.h>
  
  typedef struct {
    uint32_t idx;
  } rb_js_abi_host_js_abi_value_t;
  void rb_js_abi_host_js_abi_value_free(rb_js_abi_host_js_abi_value_t *ptr);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_js_abi_value_clone(rb_js_abi_host_js_abi_value_t *ptr);
  
  typedef struct {
    char *ptr;
    size_t len;
  } rb_js_abi_host_string_t;
  
  void rb_js_abi_host_string_set(rb_js_abi_host_string_t *ret, const char *s);
  void rb_js_abi_host_string_dup(rb_js_abi_host_string_t *ret, const char *s);
  void rb_js_abi_host_string_free(rb_js_abi_host_string_t *ret);
  typedef struct {
    uint8_t tag;
    union {
      rb_js_abi_host_js_abi_value_t success;
      rb_js_abi_host_js_abi_value_t failure;
    } val;
  } rb_js_abi_host_js_abi_result_t;
  #define RB_JS_ABI_HOST_JS_ABI_RESULT_SUCCESS 0
  #define RB_JS_ABI_HOST_JS_ABI_RESULT_FAILURE 1
  void rb_js_abi_host_js_abi_result_free(rb_js_abi_host_js_abi_result_t *ptr);
  typedef struct {
    uint8_t tag;
    union {
      double as_float;
      rb_js_abi_host_string_t bignum;
    } val;
  } rb_js_abi_host_raw_integer_t;
  #define RB_JS_ABI_HOST_RAW_INTEGER_AS_FLOAT 0
  #define RB_JS_ABI_HOST_RAW_INTEGER_BIGNUM 1
  void rb_js_abi_host_raw_integer_free(rb_js_abi_host_raw_integer_t *ptr);
  typedef struct {
    rb_js_abi_host_js_abi_value_t *ptr;
    size_t len;
  } rb_js_abi_host_list_js_abi_value_t;
  void rb_js_abi_host_list_js_abi_value_free(rb_js_abi_host_list_js_abi_value_t *ptr);
  void rb_js_abi_host_eval_js(rb_js_abi_host_string_t *code, rb_js_abi_host_js_abi_result_t *ret0);
  bool rb_js_abi_host_is_js(rb_js_abi_host_js_abi_value_t value);
  bool rb_js_abi_host_instance_of(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_js_abi_value_t klass);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_global_this(void);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_int_to_js_number(int32_t value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_float_to_js_number(double value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_string_to_js_string(rb_js_abi_host_string_t *value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_bool_to_js_bool(bool value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_proc_to_js_function(uint32_t value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_rb_object_to_js_rb_value(uint32_t raw_rb_abi_value);
  void rb_js_abi_host_js_value_to_string(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0);
  void rb_js_abi_host_js_value_to_integer(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_raw_integer_t *ret0);
  void rb_js_abi_host_export_js_value_to_host(rb_js_abi_host_js_abi_value_t value);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_import_js_value_from_host(void);
  void rb_js_abi_host_js_value_typeof(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0);
  bool rb_js_abi_host_js_value_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs);
  bool rb_js_abi_host_js_value_strictly_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs);
  void rb_js_abi_host_reflect_apply(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t this_argument, rb_js_abi_host_list_js_abi_value_t *arguments, rb_js_abi_host_js_abi_result_t *ret0);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_construct(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *arguments);
  bool rb_js_abi_host_reflect_delete_property(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key);
  void rb_js_abi_host_reflect_get(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key, rb_js_abi_host_js_abi_result_t *ret0);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_own_property_descriptor(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key);
  rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_prototype_of(rb_js_abi_host_js_abi_value_t target);
  bool rb_js_abi_host_reflect_has(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key);
  bool rb_js_abi_host_reflect_is_extensible(rb_js_abi_host_js_abi_value_t target);
  void rb_js_abi_host_reflect_own_keys(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *ret0);
  bool rb_js_abi_host_reflect_prevent_extensions(rb_js_abi_host_js_abi_value_t target);
  void rb_js_abi_host_reflect_set(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key, rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_js_abi_result_t *ret0);
  bool rb_js_abi_host_reflect_set_prototype_of(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t prototype);
  #ifdef __cplusplus
}
#endif
#endif
