// Generated by `wit-bindgen` 0.24.0. DO NOT EDIT!
#include "ext.h"
#include <stdlib.h>
#include <string.h>

// Imported Functions from `ruby:js/js-runtime`

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("eval-js")))
extern void __wasm_import_ruby_js_js_runtime_eval_js(uint8_t *, size_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("is-js")))
extern int32_t __wasm_import_ruby_js_js_runtime_is_js(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("instance-of")))
extern int32_t __wasm_import_ruby_js_js_runtime_instance_of(int32_t, int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("global-this")))
extern int32_t __wasm_import_ruby_js_js_runtime_global_this(void);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("int-to-js-number")))
extern int32_t __wasm_import_ruby_js_js_runtime_int_to_js_number(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("float-to-js-number")))
extern int32_t __wasm_import_ruby_js_js_runtime_float_to_js_number(double);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("string-to-js-string")))
extern int32_t __wasm_import_ruby_js_js_runtime_string_to_js_string(uint8_t *, size_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("bool-to-js-bool")))
extern int32_t __wasm_import_ruby_js_js_runtime_bool_to_js_bool(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("proc-to-js-function")))
extern int32_t __wasm_import_ruby_js_js_runtime_proc_to_js_function(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("rb-object-to-js-rb-value")))
extern int32_t __wasm_import_ruby_js_js_runtime_rb_object_to_js_rb_value(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("js-value-to-string")))
extern void __wasm_import_ruby_js_js_runtime_js_value_to_string(int32_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("js-value-to-integer")))
extern void __wasm_import_ruby_js_js_runtime_js_value_to_integer(int32_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("export-js-value-to-host")))
extern void __wasm_import_ruby_js_js_runtime_export_js_value_to_host(int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("import-js-value-from-host")))
extern int32_t __wasm_import_ruby_js_js_runtime_import_js_value_from_host(void);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("js-value-typeof")))
extern void __wasm_import_ruby_js_js_runtime_js_value_typeof(int32_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("js-value-equal")))
extern int32_t __wasm_import_ruby_js_js_runtime_js_value_equal(int32_t, int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("js-value-strictly-equal")))
extern int32_t __wasm_import_ruby_js_js_runtime_js_value_strictly_equal(int32_t, int32_t);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("reflect-apply")))
extern void __wasm_import_ruby_js_js_runtime_reflect_apply(int32_t, int32_t, uint8_t *, size_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("reflect-get")))
extern void __wasm_import_ruby_js_js_runtime_reflect_get(int32_t, uint8_t *, size_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("reflect-set")))
extern void __wasm_import_ruby_js_js_runtime_reflect_set(int32_t, uint8_t *, size_t, int32_t, uint8_t *);

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("throw-prohibit-rewind-exception")))
extern void __wasm_import_ruby_js_js_runtime_throw_prohibit_rewind_exception(uint8_t *, size_t);

// Exported Functions from `ruby:js/ruby-runtime`












__attribute__((__weak__, __export_name__("cabi_post_ruby:js/ruby-runtime#rstring-ptr")))
void __wasm_export_exports_ruby_js_ruby_runtime_rstring_ptr_post_return(uint8_t * arg0) {
  if ((*((size_t*) (arg0 + 4))) > 0) {
    free(*((uint8_t **) (arg0 + 0)));
  }
}







// Canonical ABI intrinsics

__attribute__((__weak__, __export_name__("cabi_realloc")))
void *cabi_realloc(void *ptr, size_t old_size, size_t align, size_t new_size) {
  (void) old_size;
  if (new_size == 0) return (void*) align;
  void *ret = realloc(ptr, new_size);
  if (!ret) abort();
  return ret;
}

// Helper Functions

__attribute__((__import_module__("ruby:js/js-runtime"), __import_name__("[resource-drop]js-abi-value")))
extern void __wasm_import_ruby_js_js_runtime_js_abi_value_drop(int32_t handle);

void ruby_js_js_runtime_js_abi_value_drop_own(ruby_js_js_runtime_own_js_abi_value_t handle) {
  __wasm_import_ruby_js_js_runtime_js_abi_value_drop(handle.__handle);
}

ruby_js_js_runtime_borrow_js_abi_value_t ruby_js_js_runtime_borrow_js_abi_value(ruby_js_js_runtime_own_js_abi_value_t arg) {
  return (ruby_js_js_runtime_borrow_js_abi_value_t) { arg.__handle };
}

void ruby_js_js_runtime_js_abi_result_free(ruby_js_js_runtime_js_abi_result_t *ptr) {
  switch ((int32_t) ptr->tag) {
    case 0: {
      break;
    }
    case 1: {
      break;
    }
  }
}

void ruby_js_js_runtime_raw_integer_free(ruby_js_js_runtime_raw_integer_t *ptr) {
  switch ((int32_t) ptr->tag) {
    case 0: {
      break;
    }
    case 1: {
      ext_string_free(&ptr->val.bignum);
      break;
    }
  }
}

void ruby_js_js_runtime_list_borrow_js_abi_value_free(ruby_js_js_runtime_list_borrow_js_abi_value_t *ptr) {
  size_t list_len = ptr->len;
  if (list_len > 0) {
    ruby_js_js_runtime_borrow_js_abi_value_t *list_ptr = ptr->ptr;
    for (size_t i = 0; i < list_len; i++) {
    }
    free(list_ptr);
  }
}

__attribute__((__import_module__("ruby:js/ruby-runtime"), __import_name__("[resource-drop]rb-iseq")))
extern void __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_drop(int32_t handle);

void exports_ruby_js_ruby_runtime_rb_iseq_drop_own(exports_ruby_js_ruby_runtime_own_rb_iseq_t handle) {
  __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_drop(handle.__handle);
}

__attribute__(( __import_module__("[export]ruby:js/ruby-runtime"), __import_name__("[resource-new]rb-iseq")))
extern int32_t __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_new(int32_t);

__attribute__((__import_module__("[export]ruby:js/ruby-runtime"), __import_name__("[resource-rep]rb-iseq")))
extern int32_t __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_rep(int32_t);

exports_ruby_js_ruby_runtime_own_rb_iseq_t exports_ruby_js_ruby_runtime_rb_iseq_new(exports_ruby_js_ruby_runtime_rb_iseq_t *rep) {
  return (exports_ruby_js_ruby_runtime_own_rb_iseq_t) { __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_new((int32_t) rep) };
}

exports_ruby_js_ruby_runtime_rb_iseq_t* exports_ruby_js_ruby_runtime_rb_iseq_rep(exports_ruby_js_ruby_runtime_own_rb_iseq_t handle) {
  return (exports_ruby_js_ruby_runtime_rb_iseq_t*) __wasm_import_exports_ruby_js_ruby_runtime_rb_iseq_rep(handle.__handle);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#[dtor]rb_iseq")))
void __wasm_export_exports_ruby_js_ruby_runtime_rb_iseq_dtor(exports_ruby_js_ruby_runtime_rb_iseq_t* arg) {
  exports_ruby_js_ruby_runtime_rb_iseq_destructor(arg);
}

__attribute__((__import_module__("ruby:js/ruby-runtime"), __import_name__("[resource-drop]rb-abi-value")))
extern void __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_drop(int32_t handle);

void exports_ruby_js_ruby_runtime_rb_abi_value_drop_own(exports_ruby_js_ruby_runtime_own_rb_abi_value_t handle) {
  __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_drop(handle.__handle);
}

__attribute__(( __import_module__("[export]ruby:js/ruby-runtime"), __import_name__("[resource-new]rb-abi-value")))
extern int32_t __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_new(int32_t);

__attribute__((__import_module__("[export]ruby:js/ruby-runtime"), __import_name__("[resource-rep]rb-abi-value")))
extern int32_t __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_rep(int32_t);

exports_ruby_js_ruby_runtime_own_rb_abi_value_t exports_ruby_js_ruby_runtime_rb_abi_value_new(exports_ruby_js_ruby_runtime_rb_abi_value_t *rep) {
  return (exports_ruby_js_ruby_runtime_own_rb_abi_value_t) { __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_new((int32_t) rep) };
}

exports_ruby_js_ruby_runtime_rb_abi_value_t* exports_ruby_js_ruby_runtime_rb_abi_value_rep(exports_ruby_js_ruby_runtime_own_rb_abi_value_t handle) {
  return (exports_ruby_js_ruby_runtime_rb_abi_value_t*) __wasm_import_exports_ruby_js_ruby_runtime_rb_abi_value_rep(handle.__handle);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#[dtor]rb_abi_value")))
void __wasm_export_exports_ruby_js_ruby_runtime_rb_abi_value_dtor(exports_ruby_js_ruby_runtime_rb_abi_value_t* arg) {
  exports_ruby_js_ruby_runtime_rb_abi_value_destructor(arg);
}

void ext_list_string_free(ext_list_string_t *ptr) {
  size_t list_len = ptr->len;
  if (list_len > 0) {
    ext_string_t *list_ptr = ptr->ptr;
    for (size_t i = 0; i < list_len; i++) {
      ext_string_free(&list_ptr[i]);
    }
    free(list_ptr);
  }
}

void exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_free(exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t *ptr) {
  size_t list_len = ptr->len;
  if (list_len > 0) {
    exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t *list_ptr = ptr->ptr;
    for (size_t i = 0; i < list_len; i++) {
    }
    free(list_ptr);
  }
}

void ext_string_set(ext_string_t *ret, const char*s) {
  ret->ptr = (uint8_t*) s;
  ret->len = strlen(s);
}

void ext_string_dup(ext_string_t *ret, const char*s) {
  ret->len = strlen(s);
  ret->ptr = (uint8_t*) cabi_realloc(NULL, 0, 1, ret->len * 1);
  memcpy(ret->ptr, s, ret->len * 1);
}

void ext_string_free(ext_string_t *ret) {
  if (ret->len > 0) {
    free(ret->ptr);
  }
  ret->ptr = NULL;
  ret->len = 0;
}

// Component Adapters

__attribute__((__aligned__(4)))
static uint8_t RET_AREA[8];

void ruby_js_js_runtime_eval_js(ext_string_t *code, ruby_js_js_runtime_js_abi_result_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_eval_js((uint8_t *) (*code).ptr, (*code).len, ptr);
  ruby_js_js_runtime_js_abi_result_t variant;
  variant.tag = (int32_t) *((uint8_t*) (ptr + 0));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
    case 1: {
      variant.val.failure = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
  }
  *ret = variant;
}

bool ruby_js_js_runtime_is_js(ruby_js_js_runtime_borrow_js_abi_value_t value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_is_js((value).__handle);
  return ret;
}

bool ruby_js_js_runtime_instance_of(ruby_js_js_runtime_borrow_js_abi_value_t value, ruby_js_js_runtime_borrow_js_abi_value_t klass) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_instance_of((value).__handle, (klass).__handle);
  return ret;
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_global_this(void) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_global_this();
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_int_to_js_number(int32_t value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_int_to_js_number(value);
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_float_to_js_number(double value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_float_to_js_number(value);
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_string_to_js_string(ext_string_t *value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_string_to_js_string((uint8_t *) (*value).ptr, (*value).len);
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_bool_to_js_bool(bool value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_bool_to_js_bool(value);
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_proc_to_js_function(uint32_t value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_proc_to_js_function((int32_t) (value));
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_rb_object_to_js_rb_value(uint32_t raw_rb_abi_value) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_rb_object_to_js_rb_value((int32_t) (raw_rb_abi_value));
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

void ruby_js_js_runtime_js_value_to_string(ruby_js_js_runtime_borrow_js_abi_value_t value, ext_string_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_js_value_to_string((value).__handle, ptr);
  *ret = (ext_string_t) { (uint8_t*)(*((uint8_t **) (ptr + 0))), (*((size_t*) (ptr + 4))) };
}

void ruby_js_js_runtime_js_value_to_integer(ruby_js_js_runtime_borrow_js_abi_value_t value, ruby_js_js_runtime_raw_integer_t *ret) {
  __attribute__((__aligned__(8)))
  uint8_t ret_area[16];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_js_value_to_integer((value).__handle, ptr);
  ruby_js_js_runtime_raw_integer_t variant;
  variant.tag = (int32_t) *((uint8_t*) (ptr + 0));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.as_float = *((double*) (ptr + 8));
      break;
    }
    case 1: {
      variant.val.bignum = (ext_string_t) { (uint8_t*)(*((uint8_t **) (ptr + 8))), (*((size_t*) (ptr + 12))) };
      break;
    }
  }
  *ret = variant;
}

void ruby_js_js_runtime_export_js_value_to_host(ruby_js_js_runtime_borrow_js_abi_value_t value) {
  __wasm_import_ruby_js_js_runtime_export_js_value_to_host((value).__handle);
}

ruby_js_js_runtime_own_js_abi_value_t ruby_js_js_runtime_import_js_value_from_host(void) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_import_js_value_from_host();
  return (ruby_js_js_runtime_own_js_abi_value_t) { ret };
}

void ruby_js_js_runtime_js_value_typeof(ruby_js_js_runtime_borrow_js_abi_value_t value, ext_string_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_js_value_typeof((value).__handle, ptr);
  *ret = (ext_string_t) { (uint8_t*)(*((uint8_t **) (ptr + 0))), (*((size_t*) (ptr + 4))) };
}

bool ruby_js_js_runtime_js_value_equal(ruby_js_js_runtime_borrow_js_abi_value_t lhs, ruby_js_js_runtime_borrow_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_js_value_equal((lhs).__handle, (rhs).__handle);
  return ret;
}

bool ruby_js_js_runtime_js_value_strictly_equal(ruby_js_js_runtime_borrow_js_abi_value_t lhs, ruby_js_js_runtime_borrow_js_abi_value_t rhs) {
  int32_t ret = __wasm_import_ruby_js_js_runtime_js_value_strictly_equal((lhs).__handle, (rhs).__handle);
  return ret;
}

void ruby_js_js_runtime_reflect_apply(ruby_js_js_runtime_borrow_js_abi_value_t target, ruby_js_js_runtime_borrow_js_abi_value_t this_argument, ruby_js_js_runtime_list_borrow_js_abi_value_t *arguments, ruby_js_js_runtime_js_abi_result_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_reflect_apply((target).__handle, (this_argument).__handle, (uint8_t *) (*arguments).ptr, (*arguments).len, ptr);
  ruby_js_js_runtime_js_abi_result_t variant;
  variant.tag = (int32_t) *((uint8_t*) (ptr + 0));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
    case 1: {
      variant.val.failure = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
  }
  *ret = variant;
}

void ruby_js_js_runtime_reflect_get(ruby_js_js_runtime_borrow_js_abi_value_t target, ext_string_t *property_key, ruby_js_js_runtime_js_abi_result_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_reflect_get((target).__handle, (uint8_t *) (*property_key).ptr, (*property_key).len, ptr);
  ruby_js_js_runtime_js_abi_result_t variant;
  variant.tag = (int32_t) *((uint8_t*) (ptr + 0));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
    case 1: {
      variant.val.failure = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
  }
  *ret = variant;
}

void ruby_js_js_runtime_reflect_set(ruby_js_js_runtime_borrow_js_abi_value_t target, ext_string_t *property_key, ruby_js_js_runtime_borrow_js_abi_value_t value, ruby_js_js_runtime_js_abi_result_t *ret) {
  __attribute__((__aligned__(4)))
  uint8_t ret_area[8];
  uint8_t *ptr = (uint8_t *) &ret_area;
  __wasm_import_ruby_js_js_runtime_reflect_set((target).__handle, (uint8_t *) (*property_key).ptr, (*property_key).len, (value).__handle, ptr);
  ruby_js_js_runtime_js_abi_result_t variant;
  variant.tag = (int32_t) *((uint8_t*) (ptr + 0));
  switch ((int32_t) variant.tag) {
    case 0: {
      variant.val.success = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
    case 1: {
      variant.val.failure = (ruby_js_js_runtime_own_js_abi_value_t) { *((int32_t*) (ptr + 4)) };
      break;
    }
  }
  *ret = variant;
}

void ruby_js_js_runtime_throw_prohibit_rewind_exception(ext_string_t *message) {
  __wasm_import_ruby_js_js_runtime_throw_prohibit_rewind_exception((uint8_t *) (*message).ptr, (*message).len);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-show-version")))
void __wasm_export_exports_ruby_js_ruby_runtime_ruby_show_version(void) {
  exports_ruby_js_ruby_runtime_ruby_show_version();
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-init")))
void __wasm_export_exports_ruby_js_ruby_runtime_ruby_init(void) {
  exports_ruby_js_ruby_runtime_ruby_init();
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-sysinit")))
void __wasm_export_exports_ruby_js_ruby_runtime_ruby_sysinit(uint8_t * arg, size_t arg0) {
  ext_list_string_t arg1 = (ext_list_string_t) { (ext_string_t*)(arg), (arg0) };
  exports_ruby_js_ruby_runtime_ruby_sysinit(&arg1);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-options")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_ruby_options(uint8_t * arg, size_t arg0) {
  ext_list_string_t arg1 = (ext_list_string_t) { (ext_string_t*)(arg), (arg0) };
  exports_ruby_js_ruby_runtime_own_rb_iseq_t ret = exports_ruby_js_ruby_runtime_ruby_options(&arg1);
  return (ret).__handle;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-script")))
void __wasm_export_exports_ruby_js_ruby_runtime_ruby_script(uint8_t * arg, size_t arg0) {
  ext_string_t arg1 = (ext_string_t) { (uint8_t*)(arg), (arg0) };
  exports_ruby_js_ruby_runtime_ruby_script(&arg1);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#ruby-init-loadpath")))
void __wasm_export_exports_ruby_js_ruby_runtime_ruby_init_loadpath(void) {
  exports_ruby_js_ruby_runtime_ruby_init_loadpath();
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-eval-string-protect")))
uint8_t * __wasm_export_exports_ruby_js_ruby_runtime_rb_eval_string_protect(uint8_t * arg, size_t arg0) {
  ext_string_t arg1 = (ext_string_t) { (uint8_t*)(arg), (arg0) };
  exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t ret;
  exports_ruby_js_ruby_runtime_rb_eval_string_protect(&arg1, &ret);
  uint8_t *ptr = (uint8_t *) &RET_AREA;
  *((int32_t*)(ptr + 0)) = ((ret).f0).__handle;
  *((int32_t*)(ptr + 4)) = (ret).f1;
  return ptr;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-funcallv-protect")))
uint8_t * __wasm_export_exports_ruby_js_ruby_runtime_rb_funcallv_protect(int32_t arg, int32_t arg0, uint8_t * arg1, size_t arg2) {
  exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t arg3 = (exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t) { (exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t*)(arg1), (arg2) };
  exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t ret;
  exports_ruby_js_ruby_runtime_rb_funcallv_protect(((exports_ruby_js_ruby_runtime_rb_abi_value_t*) arg), (uint32_t) (arg0), &arg3, &ret);
  uint8_t *ptr = (uint8_t *) &RET_AREA;
  *((int32_t*)(ptr + 0)) = ((ret).f0).__handle;
  *((int32_t*)(ptr + 4)) = (ret).f1;
  return ptr;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-intern")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_rb_intern(uint8_t * arg, size_t arg0) {
  ext_string_t arg1 = (ext_string_t) { (uint8_t*)(arg), (arg0) };
  exports_ruby_js_ruby_runtime_rb_id_t ret = exports_ruby_js_ruby_runtime_rb_intern(&arg1);
  return (int32_t) (ret);
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-errinfo")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_rb_errinfo(void) {
  exports_ruby_js_ruby_runtime_own_rb_abi_value_t ret = exports_ruby_js_ruby_runtime_rb_errinfo();
  return (ret).__handle;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-clear-errinfo")))
void __wasm_export_exports_ruby_js_ruby_runtime_rb_clear_errinfo(void) {
  exports_ruby_js_ruby_runtime_rb_clear_errinfo();
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rstring-ptr")))
uint8_t * __wasm_export_exports_ruby_js_ruby_runtime_rstring_ptr(int32_t arg) {
  ext_string_t ret;
  exports_ruby_js_ruby_runtime_rstring_ptr(((exports_ruby_js_ruby_runtime_rb_abi_value_t*) arg), &ret);
  uint8_t *ptr = (uint8_t *) &RET_AREA;
  *((size_t*)(ptr + 4)) = (ret).len;
  *((uint8_t **)(ptr + 0)) = (uint8_t *) (ret).ptr;
  return ptr;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-vm-bugreport")))
void __wasm_export_exports_ruby_js_ruby_runtime_rb_vm_bugreport(void) {
  exports_ruby_js_ruby_runtime_rb_vm_bugreport();
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-gc-enable")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_rb_gc_enable(void) {
  bool ret = exports_ruby_js_ruby_runtime_rb_gc_enable();
  return ret;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-gc-disable")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_rb_gc_disable(void) {
  bool ret = exports_ruby_js_ruby_runtime_rb_gc_disable();
  return ret;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#rb-set-should-prohibit-rewind")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_rb_set_should_prohibit_rewind(int32_t arg) {
  bool ret = exports_ruby_js_ruby_runtime_rb_set_should_prohibit_rewind(arg);
  return ret;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#wrap-js-value")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_wrap_js_value(int32_t arg) {
  exports_ruby_js_ruby_runtime_own_rb_abi_value_t ret = exports_ruby_js_ruby_runtime_wrap_js_value((exports_ruby_js_ruby_runtime_own_js_abi_value_t) { arg });
  return (ret).__handle;
}

__attribute__((__export_name__("ruby:js/ruby-runtime#to-js-value")))
int32_t __wasm_export_exports_ruby_js_ruby_runtime_to_js_value(int32_t arg) {
  exports_ruby_js_ruby_runtime_own_js_abi_value_t ret = exports_ruby_js_ruby_runtime_to_js_value(((exports_ruby_js_ruby_runtime_rb_abi_value_t*) arg));
  return (ret).__handle;
}

// Ensure that the *_component_type.o object is linked in

extern void __component_type_object_force_link_ext(void);
void __component_type_object_force_link_ext_public_use_in_this_compilation_unit(void) {
  __component_type_object_force_link_ext();
}
