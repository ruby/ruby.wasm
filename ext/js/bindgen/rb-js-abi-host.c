#include <stdlib.h>
#include <rb-js-abi-host.h>

__attribute__((weak, export_name("canonical_abi_realloc")))
void *canonical_abi_realloc(
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

__attribute__((weak, export_name("canonical_abi_free")))
void canonical_abi_free(
void *ptr,
size_t size,
size_t align
) {
  free(ptr);
}

__attribute__((import_module("canonical_abi"), import_name("resource_drop_js-abi-value")))
void __resource_js_abi_value_drop(uint32_t idx);

void rb_js_abi_host_js_abi_value_free(rb_js_abi_host_js_abi_value_t *ptr) {
  __resource_js_abi_value_drop(ptr->idx);
}

__attribute__((import_module("canonical_abi"), import_name("resource_clone_js-abi-value")))
uint32_t __resource_js_abi_value_clone(uint32_t idx);

rb_js_abi_host_js_abi_value_t rb_js_abi_host_js_abi_value_clone(rb_js_abi_host_js_abi_value_t *ptr) {
  return (rb_js_abi_host_js_abi_value_t){__resource_js_abi_value_clone(ptr->idx)};
}
#include <string.h>

void rb_js_abi_host_string_set(rb_js_abi_host_string_t *ret, const char *s) {
  ret->ptr = (char*) s;
  ret->len = strlen(s);
}

void rb_js_abi_host_string_dup(rb_js_abi_host_string_t *ret, const char *s) {
  ret->len = strlen(s);
  ret->ptr = canonical_abi_realloc(NULL, 0, 1, ret->len);
  memcpy(ret->ptr, s, ret->len);
}

void rb_js_abi_host_string_free(rb_js_abi_host_string_t *ret) {
  canonical_abi_free(ret->ptr, ret->len, 1);
  ret->ptr = NULL;
  ret->len = 0;
}
void rb_js_abi_host_list_js_abi_value_free(rb_js_abi_host_list_js_abi_value_t *ptr) {
  for (size_t i = 0; i < ptr->len; i++) {
    rb_js_abi_host_js_abi_value_free(&ptr->ptr[i]);
  }
  canonical_abi_free(ptr->ptr, ptr->len * 4, 4);
}
static int64_t RET_AREA[2];
__attribute__((import_module("rb-js-abi-host"), import_name("eval-js")))
int32_t __wasm_import_rb_js_abi_host_eval_js(int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_eval_js(rb_js_abi_host_string_t *code) {
  int32_t ret = __wasm_import_rb_js_abi_host_eval_js((int32_t) (*code).ptr, (int32_t) (*code).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("is-js")))
int32_t __wasm_import_rb_js_abi_host_is_js(int32_t);
bool rb_js_abi_host_is_js(rb_js_abi_host_js_abi_value_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_is_js((value).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("instance-of")))
int32_t __wasm_import_rb_js_abi_host_instance_of(int32_t, int32_t);
bool rb_js_abi_host_instance_of(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_js_abi_value_t klass) {
  int32_t ret = __wasm_import_rb_js_abi_host_instance_of((value).idx, (klass).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("global-this")))
int32_t __wasm_import_rb_js_abi_host_global_this(void);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_global_this(void) {
  int32_t ret = __wasm_import_rb_js_abi_host_global_this();
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("int-to-js-number")))
int32_t __wasm_import_rb_js_abi_host_int_to_js_number(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_int_to_js_number(int32_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_int_to_js_number(value);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("string-to-js-string")))
int32_t __wasm_import_rb_js_abi_host_string_to_js_string(int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_string_to_js_string(rb_js_abi_host_string_t *value) {
  int32_t ret = __wasm_import_rb_js_abi_host_string_to_js_string((int32_t) (*value).ptr, (int32_t) (*value).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("bool-to-js-bool")))
int32_t __wasm_import_rb_js_abi_host_bool_to_js_bool(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_bool_to_js_bool(bool value) {
  int32_t variant;
  switch ((int32_t) value) {
    case 0: {
      variant = 0;
      break;
    }
    case 1: {
      variant = 1;
      break;
    }
  }
  int32_t ret = __wasm_import_rb_js_abi_host_bool_to_js_bool(variant);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("proc-to-js-function")))
int32_t __wasm_import_rb_js_abi_host_proc_to_js_function(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_proc_to_js_function(uint32_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_proc_to_js_function((int32_t) (value));
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("rb-object-to-js-rb-value")))
int32_t __wasm_import_rb_js_abi_host_rb_object_to_js_rb_value(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_rb_object_to_js_rb_value(uint32_t raw_rb_abi_value) {
  int32_t ret = __wasm_import_rb_js_abi_host_rb_object_to_js_rb_value((int32_t) (raw_rb_abi_value));
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-to-string")))
void __wasm_import_rb_js_abi_host_js_value_to_string(int32_t, int32_t);
void rb_js_abi_host_js_value_to_string(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0) {
  int32_t ptr = (int32_t) &RET_AREA;
  __wasm_import_rb_js_abi_host_js_value_to_string((value).idx, ptr);
  *ret0 = (rb_js_abi_host_string_t) { (char*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 8))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("export-js-value-to-host")))
void __wasm_import_rb_js_abi_host_export_js_value_to_host(int32_t);
void rb_js_abi_host_export_js_value_to_host(rb_js_abi_host_js_abi_value_t value) {
  __wasm_import_rb_js_abi_host_export_js_value_to_host((value).idx);
}
__attribute__((import_module("rb-js-abi-host"), import_name("import-js-value-from-host")))
int32_t __wasm_import_rb_js_abi_host_import_js_value_from_host(void);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_import_js_value_from_host(void) {
  int32_t ret = __wasm_import_rb_js_abi_host_import_js_value_from_host();
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-typeof")))
void __wasm_import_rb_js_abi_host_js_value_typeof(int32_t, int32_t);
void rb_js_abi_host_js_value_typeof(rb_js_abi_host_js_abi_value_t value, rb_js_abi_host_string_t *ret0) {
  int32_t ptr = (int32_t) &RET_AREA;
  __wasm_import_rb_js_abi_host_js_value_typeof((value).idx, ptr);
  *ret0 = (rb_js_abi_host_string_t) { (char*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 8))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-equal")))
int32_t __wasm_import_rb_js_abi_host_js_value_equal(int32_t, int32_t);
bool rb_js_abi_host_js_value_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_rb_js_abi_host_js_value_equal((lhs).idx, (rhs).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("js-value-strictly-equal")))
int32_t __wasm_import_rb_js_abi_host_js_value_strictly_equal(int32_t, int32_t);
bool rb_js_abi_host_js_value_strictly_equal(rb_js_abi_host_js_abi_value_t lhs, rb_js_abi_host_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_rb_js_abi_host_js_value_strictly_equal((lhs).idx, (rhs).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-apply")))
int32_t __wasm_import_rb_js_abi_host_reflect_apply(int32_t, int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_apply(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t this_argument, rb_js_abi_host_list_js_abi_value_t *arguments) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_apply((target).idx, (this_argument).idx, (int32_t) (*arguments).ptr, (int32_t) (*arguments).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-construct")))
int32_t __wasm_import_rb_js_abi_host_reflect_construct(int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_construct(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *arguments) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_construct((target).idx, (int32_t) (*arguments).ptr, (int32_t) (*arguments).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-delete-property")))
int32_t __wasm_import_rb_js_abi_host_reflect_delete_property(int32_t, int32_t, int32_t);
bool rb_js_abi_host_reflect_delete_property(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_delete_property((target).idx, (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get")))
int32_t __wasm_import_rb_js_abi_host_reflect_get(int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_get((target).idx, (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get-own-property-descriptor")))
int32_t __wasm_import_rb_js_abi_host_reflect_get_own_property_descriptor(int32_t, int32_t, int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_own_property_descriptor(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_get_own_property_descriptor((target).idx, (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-get-prototype-of")))
int32_t __wasm_import_rb_js_abi_host_reflect_get_prototype_of(int32_t);
rb_js_abi_host_js_abi_value_t rb_js_abi_host_reflect_get_prototype_of(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_get_prototype_of((target).idx);
  return (rb_js_abi_host_js_abi_value_t){ ret };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-has")))
int32_t __wasm_import_rb_js_abi_host_reflect_has(int32_t, int32_t, int32_t);
bool rb_js_abi_host_reflect_has(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_has((target).idx, (int32_t) (*property_key).ptr, (int32_t) (*property_key).len);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-is-extensible")))
int32_t __wasm_import_rb_js_abi_host_reflect_is_extensible(int32_t);
bool rb_js_abi_host_reflect_is_extensible(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_is_extensible((target).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-own-keys")))
void __wasm_import_rb_js_abi_host_reflect_own_keys(int32_t, int32_t);
void rb_js_abi_host_reflect_own_keys(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_list_js_abi_value_t *ret0) {
  int32_t ptr = (int32_t) &RET_AREA;
  __wasm_import_rb_js_abi_host_reflect_own_keys((target).idx, ptr);
  *ret0 = (rb_js_abi_host_list_js_abi_value_t) { (rb_js_abi_host_js_abi_value_t*)(*((int32_t*) (ptr + 0))), (size_t)(*((int32_t*) (ptr + 8))) };
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-prevent-extensions")))
int32_t __wasm_import_rb_js_abi_host_reflect_prevent_extensions(int32_t);
bool rb_js_abi_host_reflect_prevent_extensions(rb_js_abi_host_js_abi_value_t target) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_prevent_extensions((target).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-set")))
int32_t __wasm_import_rb_js_abi_host_reflect_set(int32_t, int32_t, int32_t, int32_t);
bool rb_js_abi_host_reflect_set(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_string_t *property_key, rb_js_abi_host_js_abi_value_t value) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_set((target).idx, (int32_t) (*property_key).ptr, (int32_t) (*property_key).len, (value).idx);
  return ret;
}
__attribute__((import_module("rb-js-abi-host"), import_name("reflect-set-prototype-of")))
int32_t __wasm_import_rb_js_abi_host_reflect_set_prototype_of(int32_t, int32_t);
bool rb_js_abi_host_reflect_set_prototype_of(rb_js_abi_host_js_abi_value_t target, rb_js_abi_host_js_abi_value_t prototype) {
  int32_t ret = __wasm_import_rb_js_abi_host_reflect_set_prototype_of((target).idx, (prototype).idx);
  return ret;
}
