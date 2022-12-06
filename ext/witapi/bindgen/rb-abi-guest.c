#include <stdlib.h>
#include <rb-abi-guest.h>

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
__attribute__((export_name("ruby-script: func(name: string) -> ()")))
void __wasm_export_rb_abi_guest_ruby_script(int32_t arg, int32_t arg0) {
  rb_abi_guest_string_t arg1 = (rb_abi_guest_string_t) { (char*)(arg), (size_t)(arg0) };
  rb_abi_guest_ruby_script(&arg1);
}
__attribute__((export_name("ruby-init-loadpath: func() -> ()")))
void __wasm_export_rb_abi_guest_ruby_init_loadpath(void) {
  rb_abi_guest_ruby_init_loadpath();
}
