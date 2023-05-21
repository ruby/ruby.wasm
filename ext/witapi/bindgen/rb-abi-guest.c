#include <stdlib.h>
#include <rb-abi-guest.h>

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

void rb_abi_guest_string_set(rb_abi_guest_string_t *ret, const char *s) {
  ret->ptr = (char*) s;
  ret->len = strlen(s);
}

void rb_abi_guest_string_dup(rb_abi_guest_string_t *ret, const char *s) {
  ret->len = strlen(s);
  ret->ptr = cabi_realloc(NULL, 0, 1, ret->len);
  memcpy(ret->ptr, s, ret->len);
}

void rb_abi_guest_string_free(rb_abi_guest_string_t *ret) {
  if (ret->len > 0) {
    free(ret->ptr);
  }
  ret->ptr = NULL;
  ret->len = 0;
}
void rb_abi_guest_list_string_free(rb_abi_guest_list_string_t *ptr) {
  for (size_t i = 0; i < ptr->len; i++) {
    rb_abi_guest_string_free(&ptr->ptr[i]);
  }
  if (ptr->len > 0) {
    free(ptr->ptr);
  }
}
void rb_abi_guest_list_rb_abi_value_free(rb_abi_guest_list_rb_abi_value_t *ptr) {
  if (ptr->len > 0) {
    free(ptr->ptr);
  }
}

__attribute__((aligned(4)))
static uint8_t RET_AREA[8];
__attribute__((export_name("ruby-show-version: func() -> ()")))
void __wasm_export_rb_abi_guest_ruby_show_version(void) {
  rb_abi_guest_ruby_show_version();
}
__attribute__((export_name("ruby-init: func() -> ()")))
void __wasm_export_rb_abi_guest_ruby_init(void) {
  rb_abi_guest_ruby_init();
}
__attribute__((export_name("ruby-sysinit: func(args: list<string>) -> ()")))
void __wasm_export_rb_abi_guest_ruby_sysinit(int32_t arg, int32_t arg0) {
  rb_abi_guest_list_string_t arg1 = (rb_abi_guest_list_string_t) { (rb_abi_guest_string_t*)(arg), (size_t)(arg0) };
  rb_abi_guest_ruby_sysinit(&arg1);
}
__attribute__((export_name("ruby-options: func(args: list<string>) -> u32")))
int32_t __wasm_export_rb_abi_guest_ruby_options(int32_t arg, int32_t arg0) {
  rb_abi_guest_list_string_t arg1 = (rb_abi_guest_list_string_t) { (rb_abi_guest_string_t*)(arg), (size_t)(arg0) };
  rb_abi_guest_rb_abi_value_t ret = rb_abi_guest_ruby_options(&arg1);
  return (int32_t) (ret);
}
__attribute__((export_name("ruby-script: func(name: string) -> ()")))
void __wasm_export_rb_abi_guest_ruby_script(int32_t arg, int32_t arg0) {
  rb_abi_guest_string_t arg1 = (rb_abi_guest_string_t) { (char*)(arg), (size_t)(arg0) };
  rb_abi_guest_ruby_script(&arg1);
}
__attribute__((export_name("ruby-init-loadpath: func() -> ()")))
void __wasm_export_rb_abi_guest_ruby_init_loadpath(void) {
  rb_abi_guest_ruby_init_loadpath();
}
__attribute__((export_name("rb-eval-string-protect: func(str: string) -> tuple<u32, s32>")))
int32_t __wasm_export_rb_abi_guest_rb_eval_string_protect(int32_t arg, int32_t arg0) {
  rb_abi_guest_string_t arg1 = (rb_abi_guest_string_t) { (char*)(arg), (size_t)(arg0) };
  rb_abi_guest_tuple2_rb_abi_value_s32_t ret;
  rb_abi_guest_rb_eval_string_protect(&arg1, &ret);
  int32_t ptr = (int32_t) &RET_AREA;
  *((int32_t*)(ptr + 0)) = (int32_t) ((ret).f0);
  *((int32_t*)(ptr + 4)) = (ret).f1;
  return ptr;
}
__attribute__((export_name("rb-funcallv-protect: func(recv: u32, mid: u32, args: list<u32>) -> tuple<u32, s32>")))
int32_t __wasm_export_rb_abi_guest_rb_funcallv_protect(int32_t arg, int32_t arg0, int32_t arg1, int32_t arg2) {
  rb_abi_guest_list_rb_abi_value_t arg3 = (rb_abi_guest_list_rb_abi_value_t) { (rb_abi_guest_rb_abi_value_t*)(arg1), (size_t)(arg2) };
  rb_abi_guest_tuple2_rb_abi_value_s32_t ret;
  rb_abi_guest_rb_funcallv_protect((uint32_t) (arg), (uint32_t) (arg0), &arg3, &ret);
  int32_t ptr = (int32_t) &RET_AREA;
  *((int32_t*)(ptr + 0)) = (int32_t) ((ret).f0);
  *((int32_t*)(ptr + 4)) = (ret).f1;
  return ptr;
}
__attribute__((export_name("rb-intern: func(name: string) -> u32")))
int32_t __wasm_export_rb_abi_guest_rb_intern(int32_t arg, int32_t arg0) {
  rb_abi_guest_string_t arg1 = (rb_abi_guest_string_t) { (char*)(arg), (size_t)(arg0) };
  rb_abi_guest_rb_id_t ret = rb_abi_guest_rb_intern(&arg1);
  return (int32_t) (ret);
}
__attribute__((export_name("rb-errinfo: func() -> u32")))
int32_t __wasm_export_rb_abi_guest_rb_errinfo(void) {
  rb_abi_guest_rb_abi_value_t ret = rb_abi_guest_rb_errinfo();
  return (int32_t) (ret);
}
__attribute__((export_name("rb-clear-errinfo: func() -> ()")))
void __wasm_export_rb_abi_guest_rb_clear_errinfo(void) {
  rb_abi_guest_rb_clear_errinfo();
}
__attribute__((export_name("rstring-ptr: func(value: u32) -> string")))
int32_t __wasm_export_rb_abi_guest_rstring_ptr(int32_t arg) {
  rb_abi_guest_string_t ret;
  rb_abi_guest_rstring_ptr((uint32_t) (arg), &ret);
  int32_t ptr = (int32_t) &RET_AREA;
  *((int32_t*)(ptr + 4)) = (int32_t) (ret).len;
  *((int32_t*)(ptr + 0)) = (int32_t) (ret).ptr;
  return ptr;
}
__attribute__((export_name("cabi_post_rstring-ptr")))
void __wasm_export_rb_abi_guest_rstring_ptr_post_return(int32_t arg0) {
  if ((*((int32_t*) (arg0 + 4))) > 0) {
    free((void*) (*((int32_t*) (arg0 + 0))));
  }
}
__attribute__((export_name("rb-vm-bugreport: func() -> ()")))
void __wasm_export_rb_abi_guest_rb_vm_bugreport(void) {
  rb_abi_guest_rb_vm_bugreport();
}
__attribute__((export_name("rb-gc-enable: func() -> bool")))
int32_t __wasm_export_rb_abi_guest_rb_gc_enable(void) {
  bool ret = rb_abi_guest_rb_gc_enable();
  return ret;
}
__attribute__((export_name("rb-gc-disable: func() -> bool")))
int32_t __wasm_export_rb_abi_guest_rb_gc_disable(void) {
  bool ret = rb_abi_guest_rb_gc_disable();
  return ret;
}
__attribute__((export_name("rb-set-should-prohibit-rewind: func(new-value: bool) -> bool")))
int32_t __wasm_export_rb_abi_guest_rb_set_should_prohibit_rewind(int32_t arg) {
  bool ret = rb_abi_guest_rb_set_should_prohibit_rewind(arg);
  return ret;
}
