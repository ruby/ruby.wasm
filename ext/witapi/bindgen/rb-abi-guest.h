#ifndef __BINDINGS_RB_ABI_GUEST_H
#define __BINDINGS_RB_ABI_GUEST_H
#ifdef __cplusplus
extern "C"
{
  #endif

  #include <stdint.h>
  #include <stdbool.h>

  typedef struct {
    char *ptr;
    size_t len;
  } rb_abi_guest_string_t;

  void rb_abi_guest_string_set(rb_abi_guest_string_t *ret, const char *s);
  void rb_abi_guest_string_dup(rb_abi_guest_string_t *ret, const char *s);
  void rb_abi_guest_string_free(rb_abi_guest_string_t *ret);
  typedef int32_t rb_abi_guest_rb_errno_t;
  typedef uint32_t rb_abi_guest_rb_id_t;
  typedef struct {
    rb_abi_guest_string_t *ptr;
    size_t len;
  } rb_abi_guest_list_string_t;
  void rb_abi_guest_ruby_show_version(void);
  void rb_abi_guest_ruby_init(void);
  void rb_abi_guest_ruby_sysinit(rb_abi_guest_list_string_t *args);
  void rb_abi_guest_ruby_script(rb_abi_guest_string_t *name);
  void rb_abi_guest_ruby_init_loadpath(void);
  #ifdef __cplusplus
}
#endif
#endif
