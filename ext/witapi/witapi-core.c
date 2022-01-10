#include <stdlib.h>

#include "ruby.h"

#include "bindgen/rb-abi-guest.h"

__attribute__((import_module("asyncify"), import_name("start_unwind"))) void
asyncify_start_unwind(void *buf);
__attribute__((import_module("asyncify"), import_name("stop_unwind"))) void
asyncify_stop_unwind(void);
__attribute__((import_module("asyncify"), import_name("start_rewind"))) void
asyncify_start_rewind(void *buf);
__attribute__((import_module("asyncify"), import_name("stop_rewind"))) void
asyncify_stop_rewind(void);

void *rb_wasm_handle_jmp_unwind(void);
void *rb_wasm_handle_scan_unwind(void);
void *rb_wasm_handle_fiber_unwind(void (**new_fiber_entry)(void *, void *),
                                  void **arg0, void **arg1,
                                  bool *is_new_fiber_started);

#define RB_WASM_LIB_RT(MAIN_ENTRY)                                             \
  {                                                                            \
                                                                               \
    void *arg0 = NULL, *arg1 = NULL;                                           \
    void (*fiber_entry_point)(void *, void *) = NULL;                          \
                                                                               \
    while (1) {                                                                \
      if (fiber_entry_point) {                                                 \
        fiber_entry_point(arg0, arg1);                                         \
      } else {                                                                 \
        MAIN_ENTRY;                                                            \
      }                                                                        \
                                                                               \
      bool new_fiber_started = false;                                          \
      void *asyncify_buf;                                                      \
      asyncify_stop_unwind();                                                  \
                                                                               \
      if ((asyncify_buf = rb_wasm_handle_jmp_unwind()) != NULL) {              \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      }                                                                        \
      if ((asyncify_buf = rb_wasm_handle_scan_unwind()) != NULL) {             \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      }                                                                        \
                                                                               \
      asyncify_buf = rb_wasm_handle_fiber_unwind(&fiber_entry_point, &arg0,    \
                                                 &arg1, &new_fiber_started);   \
      if (asyncify_buf) {                                                      \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      } else if (new_fiber_started) {                                          \
        continue;                                                              \
      }                                                                        \
                                                                               \
      break;                                                                   \
    }                                                                          \
  }

#define c_strings_from_abi(list, new_args)                                     \
  {                                                                            \
    new_args = alloca(sizeof(char *) * ((list)->len + 1));                     \
    for (size_t i = 0; i < (list)->len; i++) {                                 \
      new_args[i] = (list)->ptr[i].ptr;                                        \
    }                                                                          \
  }

static VALUE rb_abi_guest_arena_hash;
static void rb_abi_lend_object_internal(VALUE obj) {
  VALUE ref_count = rb_hash_lookup(rb_abi_guest_arena_hash, obj);
  if (NIL_P(ref_count)) {
    rb_hash_aset(rb_abi_guest_arena_hash, obj, INT2FIX(1));
  } else {
    rb_hash_aset(rb_abi_guest_arena_hash, obj, INT2FIX(FIX2INT(ref_count) + 1));
  }
}
static void rb_abi_lend_object(VALUE obj) {
  RB_WASM_LIB_RT(rb_abi_lend_object_internal(obj));
}

void rb_abi_guest_rb_value_dtor(void *data) {
  VALUE obj = (VALUE)data;
  VALUE ref_count = rb_hash_lookup(rb_abi_guest_arena_hash, obj);
  if (NIL_P(ref_count)) {
    rb_warning("rb_abi_guest_rb_value_dtor: double free detected");
    return;
  }
  if (ref_count == INT2FIX(1)) {
    rb_hash_delete(rb_abi_guest_arena_hash, obj);
  } else {
    rb_hash_aset(rb_abi_guest_arena_hash, obj, INT2FIX(FIX2INT(ref_count) - 1));
  }
}

// MARK: - Exported functions
// NOTE: Assume that callers always pass null terminated string by
// rb_abi_guest_string_t

void rb_abi_guest_ruby_show_version(void) { ruby_show_version(); }

void rb_abi_guest_ruby_init(void) {
  RB_WASM_LIB_RT(ruby_init())

  rb_abi_guest_arena_hash = rb_hash_new();
  rb_gc_register_mark_object(rb_abi_guest_arena_hash);
}

void rb_abi_guest_ruby_sysinit(rb_abi_guest_list_string_t *args) {
  char **c_args;
  int argc = args->len;
  c_strings_from_abi(args, c_args);
  RB_WASM_LIB_RT(ruby_sysinit(&argc, &c_args))
}

rb_abi_guest_rb_iseq_t
rb_abi_guest_ruby_options(rb_abi_guest_list_string_t *args) {
  void *result;
  char **c_args;
  c_strings_from_abi(args, c_args);
  RB_WASM_LIB_RT(result = ruby_options(args->len, c_args))
  return rb_abi_guest_rb_iseq_new(result);
}

rb_abi_guest_rb_errno_t
rb_abi_guest_ruby_run_node(rb_abi_guest_rb_iseq_t node) {
  int result;
  void *iseq = rb_abi_guest_rb_iseq_get(&node);
  RB_WASM_LIB_RT(ruby_run_node(iseq))
  return result;
}

void rb_abi_guest_ruby_script(rb_abi_guest_string_t *name) {
  RB_WASM_LIB_RT(ruby_script(name->ptr))
}

void rb_abi_guest_ruby_init_loadpath(void) {
  RB_WASM_LIB_RT(ruby_init_loadpath())
}

void rb_abi_guest_rb_eval_string_protect(rb_abi_guest_string_t *str,
                                         rb_abi_guest_rb_value_t *result,
                                         int32_t *state) {
  VALUE retval;
  RB_WASM_LIB_RT(retval = rb_eval_string_protect(str->ptr, state));
  rb_abi_lend_object(retval);

  *result = rb_abi_guest_rb_value_new((void *)retval);
}

struct rb_funcallv_thunk_ctx {
  VALUE recv;
  ID mid;
  rb_abi_guest_list_rb_value_t *args;
};

VALUE rb_funcallv_thunk(VALUE arg) {
  struct rb_funcallv_thunk_ctx *ctx = (struct rb_funcallv_thunk_ctx *)arg;
  VALUE *c_argv = alloca(sizeof(VALUE) * ctx->args->len);
  for (size_t i = 0; i < ctx->args->len; i++) {
    c_argv[i] = (VALUE)rb_abi_guest_rb_value_get(&ctx->args->ptr[i]);
  }
  return rb_funcallv(ctx->recv, ctx->mid, ctx->args->len, c_argv);
}

void rb_abi_guest_rb_funcallv_protect(rb_abi_guest_rb_value_t recv,
                                      rb_abi_guest_rb_id_t mid,
                                      rb_abi_guest_list_rb_value_t *args,
                                      rb_abi_guest_rb_value_t *ret0,
                                      int32_t *ret1) {
  VALUE retval;
  VALUE abi_recv = (VALUE)rb_abi_guest_rb_value_get(&recv);
  struct rb_funcallv_thunk_ctx ctx = {
      .recv = abi_recv, .mid = mid, .args = args};
  RB_WASM_LIB_RT(retval = rb_protect(rb_funcallv_thunk, (VALUE)&ctx, ret1));
  rb_abi_lend_object(retval);
  *ret0 = rb_abi_guest_rb_value_new((void *)retval);
}

rb_abi_guest_rb_id_t rb_abi_guest_rb_intern(rb_abi_guest_string_t *name) {
  return rb_intern(name->ptr);
}

rb_abi_guest_rb_value_t rb_abi_guest_rb_errinfo(void) {
  VALUE retval;
  RB_WASM_LIB_RT(retval = rb_errinfo());
  rb_abi_lend_object(retval);
  return rb_abi_guest_rb_value_new((void *)retval);
}

void rb_abi_guest_rstring_ptr(rb_abi_guest_rb_value_t value,
                              rb_abi_guest_string_t *ret0) {
  VALUE abi_value = (VALUE)rb_abi_guest_rb_value_get(&value);
  const char *str_ptr = (const char *)RSTRING_PTR(abi_value);
  rb_abi_guest_string_dup(ret0, str_ptr);
}

uint32_t rb_abi_guest_rb_value_data_ptr(rb_abi_guest_rb_value_t self) {
  VALUE obj = (VALUE)rb_abi_guest_rb_value_get(&self);
  return (uint32_t)DATA_PTR(obj);
}

void Init_witapi(void) {}
