#ifndef __BINDINGS_RB_ABI_GUEST_H
#define __BINDINGS_RB_ABI_GUEST_H
#ifdef __cplusplus
extern "C"
{
  #endif
  
  #include <stdint.h>
  #include <stdbool.h>
  
  typedef struct {
    uint32_t idx;
  } rb_abi_guest_rb_iseq_t;
  void rb_abi_guest_rb_iseq_free(rb_abi_guest_rb_iseq_t *ptr);
  rb_abi_guest_rb_iseq_t rb_abi_guest_rb_iseq_clone(rb_abi_guest_rb_iseq_t *ptr);
  rb_abi_guest_rb_iseq_t rb_abi_guest_rb_iseq_new(void *data);
  void* rb_abi_guest_rb_iseq_get(rb_abi_guest_rb_iseq_t *ptr);
  
  __attribute__((weak))
  void rb_abi_guest_rb_iseq_dtor(void *data);
  
  typedef struct {
    uint32_t idx;
  } rb_abi_guest_rb_abi_value_t;
  void rb_abi_guest_rb_abi_value_free(rb_abi_guest_rb_abi_value_t *ptr);
  rb_abi_guest_rb_abi_value_t rb_abi_guest_rb_abi_value_clone(rb_abi_guest_rb_abi_value_t *ptr);
  rb_abi_guest_rb_abi_value_t rb_abi_guest_rb_abi_value_new(void *data);
  void* rb_abi_guest_rb_abi_value_get(rb_abi_guest_rb_abi_value_t *ptr);
  
  __attribute__((weak))
  void rb_abi_guest_rb_abi_value_dtor(void *data);
  
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
  void rb_abi_guest_list_string_free(rb_abi_guest_list_string_t *ptr);
  typedef struct {
    rb_abi_guest_rb_abi_value_t f0;
    int32_t f1;
  } rb_abi_guest_tuple2_rb_abi_value_s32_t;
  void rb_abi_guest_tuple2_rb_abi_value_s32_free(rb_abi_guest_tuple2_rb_abi_value_s32_t *ptr);
  typedef struct {
    rb_abi_guest_rb_abi_value_t *ptr;
    size_t len;
  } rb_abi_guest_list_rb_abi_value_t;
  void rb_abi_guest_list_rb_abi_value_free(rb_abi_guest_list_rb_abi_value_t *ptr);
  void rb_abi_guest_ruby_show_version(void);
  void rb_abi_guest_ruby_init(void);
  void rb_abi_guest_ruby_sysinit(rb_abi_guest_list_string_t *args);
  rb_abi_guest_rb_iseq_t rb_abi_guest_ruby_options(rb_abi_guest_list_string_t *args);
  void rb_abi_guest_ruby_script(rb_abi_guest_string_t *name);
  void rb_abi_guest_ruby_init_loadpath(void);
  void rb_abi_guest_rb_eval_string_protect(rb_abi_guest_string_t *str, rb_abi_guest_tuple2_rb_abi_value_s32_t *ret0);
  void rb_abi_guest_rb_funcallv_protect(rb_abi_guest_rb_abi_value_t recv, rb_abi_guest_rb_id_t mid, rb_abi_guest_list_rb_abi_value_t *args, rb_abi_guest_tuple2_rb_abi_value_s32_t *ret0);
  rb_abi_guest_rb_id_t rb_abi_guest_rb_intern(rb_abi_guest_string_t *name);
  rb_abi_guest_rb_abi_value_t rb_abi_guest_rb_errinfo(void);
  void rb_abi_guest_rb_clear_errinfo(void);
  void rb_abi_guest_rstring_ptr(rb_abi_guest_rb_abi_value_t value, rb_abi_guest_string_t *ret0);
  void rb_abi_guest_rb_vm_bugreport(void);
  bool rb_abi_guest_rb_gc_enable(void);
  bool rb_abi_guest_rb_gc_disable(void);
  bool rb_abi_guest_rb_set_should_prohibit_rewind(bool new_value);
  #ifdef __cplusplus
}
#endif
#endif
