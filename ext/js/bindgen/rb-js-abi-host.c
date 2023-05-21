#include <stdlib.h>
#include <rb-js-abi-host.h>

__attribute__((weak, export_name("cabi_realloc")))
void *cabi_realloc(
void *ptr,
size_t orig_size,
size_t org_align,
size_t new_size
) {
  void *ret = realloc(ptr, new_size);
  if (!ret)
  abort();
  return ret;
}
#include <string.h>

void rb_js_abi_host_string_set(rb_js_abi_host_string_t *ret, const char *s) {
  ret->ptr = (char*) s;
  ret->len = strlen(s);
}

void rb_js_abi_host_string_dup(rb_js_abi_host_string_t *ret, const char *s) {
  ret->len = strlen(s);
  ret->ptr = cabi_realloc(NULL, 0, 1, ret->len);
  memcpy(ret->ptr, s, ret->len);
}

void rb_js_abi_host_string_free(rb_js_abi_host_string_t *ret) {
  if (ret->len > 0) {
    free(ret->ptr);
  }
  ret->ptr = NULL;
  ret->len = 0;
}
void rb_js_abi_host_raw_integer_free(rb_js_abi_host_raw_integer_t *ptr) {
  switch ((int32_t) ptr->tag) {
    case 1: {
      rb_js_abi_host_string_free(&ptr->val.bignum);
      break;
    }
  }
}
void rb_js_abi_host_list_js_abi_value_free(rb_js_abi_host_list_js_abi_value_t *ptr) {
  if (ptr->len > 0) {
    free(ptr->ptr);
  }
}
__attribute__((import_module("rb-js-abi-host"), import_name("eval-js: func(code: string) -> variant { success(u32), failure(u32) }")))
void __wasm_import_rb_js_abi_host_eval_js(int32_t, int32_t, int32_t);
void rb_js_abi_host_eval_js(rb_js_abi_host_string_t *code, rb_js_abi_host_js_abi_result_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_eval_js((int32_t) (*code).ptr, (int32_t) (*code).len, ptr);
  rb_js_abi_host_js_abi_result_t variant;
  variant.tag = (int32_t) (*((uint8_t*) (ptr + 0)));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
    case 1: {
      variant.val.failure = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
  }
  *ret0 = variant;
}
__attribute__((import_module("rb-js-abi-host"), import_name("is-js: func(value: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_is_js(int32_t);
bool rb_js_abi_host_is_js(rb_js_abi_host_js_abi_value_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_is_js((int32_t) (value));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("instance-of: func(value: u32, klass: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_instance_of(int32_t, int32_t);
bool rb_js_abi_host_instance_of(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_js_abi_value_t klass) {
  int32_t ret = __wasm_import_rb_js_abi_host_instance_of((int32_t) (value), (int32_t) (klass));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("global-this: func() -> u32")))
int32_t __wasm_import_rb_js_abi_host_global_this(void);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_global_this(void) {
  int32_t ret = __wasm_import_rb_js_abi_host_global_this();
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("int-to-js-number: func(value: s32) -> u32")))
int32_t __wasm_import_rb_js_abi_host_int_to_js_number(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_int_to_js_number(int32_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_int_to_js_number(value);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("float-to-js-number: func(value: float64) -> u32")))
int32_t __wasm_import_rb_js_abi_host_float_to_js_number(double);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_float_to_js_number(double value) {
  int32_t ret = __wasm_import_rb_js_abi_host_float_to_js_number(value);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("string-to-js-string: func(value: string) -> u32")))
int32_t __wasm_import_rb_js_abi_host_string_to_js_string(int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_string_to_js_string(rb_js_abi_host_string_t *value) {
  int32_t ret = __wasm_import_rb_js_abi_host_string_to_js_string((int32_t) (*value).ptr, (int32_t) (*value).len);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("bool-to-js-bool: func(value: bool) -> u32")))
int32_t __wasm_import_rb_js_abi_host_bool_to_js_bool(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_bool_to_js_bool(bool value) {
  int32_t ret = __wasm_import_rb_js_abi_host_bool_to_js_bool(value);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("proc-to-js-function: func(value: u32) -> u32")))
int32_t __wasm_import_rb_js_abi_host_proc_to_js_function(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_proc_to_js_function(uint32_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_proc_to_js_function((int32_t) (value));
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("rb-object-to-js-rb-value: func(raw-rb-abi-value: u32) -> u32")))
int32_t __wasm_import_rb_js_abi_host_rb_object_to_js_rb_value(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_rb_object_to_js_rb_value(uint32_t raw_rb_abi_value) {
  int32_t ret = __wasm_import_rb_js_abi_host_rb_object_to_js_rb_value((int32_t) (raw_rb_abi_value));
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-to-string: func(value: u32) -> string")))
void __wasm_import_rb_js_abi_host_js_value_to_string(int32_t, int32_t);
void rb_js_abi_host_js_value_to_string(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_js_value_to_string((int32_t) (value), ptr);
  *ret0 = (rb_js_abi_host_string_t) { (char*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 4))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-to-integer: func(value: u32) -> variant { f64(float64), bignum(string) }")))
void __wasm_import_rb_js_abi_host_js_value_to_integer(int32_t, int32_t);
void rb_js_abi_host_js_value_to_integer(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_raw_integer_t *ret0) {
  
  __attribute__((aligned(8)))
  uint8_t ret_area[16];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_js_value_to_integer((int32_t) (value), ptr);
  rb_js_abi_host_raw_integer_t variant;
  variant.tag = (int32_t) (*((uint8_t*) (ptr + 0)));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.f64 = *((double*) (ptr + 8));
      break;
    }
    case 1: {
      variant.val.bignum = (rb_js_abi_host_string_t) { (char*)(*((int32_t*) (ptr + 8))), (size_t)(*((int32_t*) (ptr + 12))) };
      break;
    }
  }
  *ret0 = variant;
}
__attribute__((import_module("rb-js-abi-host"), import_name("export-js-value-to-host: func(value: u32) -> ()")))
void __wasm_import_rb_js_abi_host_export_js_value_to_host(int32_t);
void rb_js_abi_host_export_js_value_to_host(rb_js_abi_host_js_abi_value_t value) {
  __wasm_import_rb_js_abi_host_export_js_value_to_host((int32_t) (value));
}
__attribute__((import_module("rb-js-abi-host"), import_name("import-js-value-from-host: func() -> u32")))
int32_t __wasm_import_rb_js_abi_host_import_js_value_from_host(void);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_import_js_value_from_host(void) {
  int32_t ret = __wasm_import_rb_js_abi_host_import_js_value_from_host();
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-typeof: func(value: u32) -> string")))
void __wasm_import_rb_js_abi_host_js_value_typeof(int32_t, int32_t);
void rb_js_abi_host_js_value_typeof(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_js_value_typeof((int32_t) (value), ptr);
  *ret0 = (rb_js_abi_host_string_t) { (char*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 4))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-equal: func(lhs: u32, rhs: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_js_value_equal(int32_t, int32_t);
bool rb_js_abi_host_js_value_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_rb_js_abi_host_js_value_equal((int32_t) (lhs), (int32_t) (rhs));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-strictly-equal: func(lhs: u32, rhs: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_js_value_strictly_equal(int32_t, int32_t);
bool rb_js_abi_host_js_value_strictly_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_rb_js_abi_host_js_value_strictly_equal((int32_t) (lhs), (int32_t) (rhs));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-apply: func(target: u32, this-argument: u32, arguments: list<u32>) -> variant { success(u32), failure(u32) }")))
void __wasm_import_rb_js_abi_host_reflect_apply(int32_t, int32_t, int32_t, int32_t, int32_t);
void rb_js_abi_host_reflect_apply(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t this_argument, rb_js_abi_host_list_js_abi_value_t *arguments, rb_js_abi_host_js_abi_result_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_reflect_apply((int32_t) (target), (int32_t) (this_argument), (int32_t) (*arguments).ptr, (int32_t) (*arguments).len, ptr);
  rb_js_abi_host_js_abi_result_t variant;
  variant.tag = (int32_t) (*((uint8_t*) (ptr + 0)));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
    case 1: {
      variant.val.failure = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
  }
  *ret0 = variant;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-construct: func(target: u32, arguments: list<u32>) -> u32")))
int32_t __wasm_import_rb_js_abi_host_reflect_construct(int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_construct(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *arguments) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_construct((int32_t) (target), (int32_t) (*arguments).ptr, (int32_t) (*arguments).len);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-delete-property: func(target: u32, property-key: string) -> bool")))
int32_t __wasm_import_rb_js_abi_host_reflect_delete_property(int32_t, int32_t, int32_t);
bool rb_js_abi_host_reflect_delete_property(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_delete_property((int32_t) (target), (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get: func(target: u32, property-key: string) -> variant { success(u32), failure(u32) }")))
void __wasm_import_rb_js_abi_host_reflect_get(int32_t, int32_t, int32_t, int32_t);
void rb_js_abi_host_reflect_get(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key, rb_js_abi_host_js_abi_result_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_reflect_get((int32_t) (target), (int32_t) (*property_key).ptr, (int32_t) (*property_key).len, ptr);
  rb_js_abi_host_js_abi_result_t variant;
  variant.tag = (int32_t) (*((uint8_t*) (ptr + 0)));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
    case 1: {
      variant.val.failure = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
  }
  *ret0 = variant;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get-own-property-descriptor: func(target: u32, property-key: string) -> u32")))
int32_t __wasm_import_rb_js_abi_host_reflect_get_own_property_descriptor(int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_own_property_descriptor(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_get_own_property_descriptor((int32_t) (target), (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get-prototype-of: func(target: u32) -> u32")))
int32_t __wasm_import_rb_js_abi_host_reflect_get_prototype_of(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_prototype_of(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_get_prototype_of((int32_t) (target));
  return (uint32_t) (ret);
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-has: func(target: u32, property-key: string) -> bool")))
int32_t __wasm_import_rb_js_abi_host_reflect_has(int32_t, int32_t, int32_t);
bool rb_js_abi_host_reflect_has(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_has((int32_t) (target), (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-is-extensible: func(target: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_reflect_is_extensible(int32_t);
bool rb_js_abi_host_reflect_is_extensible(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_is_extensible((int32_t) (target));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-own-keys: func(target: u32) -> list<u32>")))
void __wasm_import_rb_js_abi_host_reflect_own_keys(int32_t, int32_t);
void rb_js_abi_host_reflect_own_keys(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_reflect_own_keys((int32_t) (target), ptr);
  *ret0 = (rb_js_abi_host_list_js_abi_value_t) { (rb_js_abi_host_js_abi_value_t*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 4))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-prevent-extensions: func(target: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_reflect_prevent_extensions(int32_t);
bool rb_js_abi_host_reflect_prevent_extensions(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_prevent_extensions((int32_t) (target));
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-set: func(target: u32, property-key: string, value: u32) -> variant { success(u32), failure(u32) }")))
void __wasm_import_rb_js_abi_host_reflect_set(int32_t, int32_t, int32_t, int32_t, int32_t);
void rb_js_abi_host_reflect_set(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key, rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_js_abi_result_t *ret0) {
  
  __attribute__((aligned(4)))
  uint8_t ret_area[8];
  int32_t ptr = (int32_t) &ret_area;
  __wasm_import_rb_js_abi_host_reflect_set((int32_t) (target), (int32_t) (*property_key).ptr, (int32_t) (*property_key).len, (int32_t) (value), ptr);
  rb_js_abi_host_js_abi_result_t variant;
  variant.tag = (int32_t) (*((uint8_t*) (ptr + 0)));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
    case 1: {
      variant.val.failure = (uint32_t) (*((int32_t*) (ptr + 4)));
      break;
    }
  }
  *ret0 = variant;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-set-prototype-of: func(target: u32, prototype: u32) -> bool")))
int32_t __wasm_import_rb_js_abi_host_reflect_set_prototype_of(int32_t, int32_t);
bool rb_js_abi_host_reflect_set_prototype_of(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t prototype) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_set_prototype_of((int32_t) (target), (int32_t) (prototype));
  return ret;
}
