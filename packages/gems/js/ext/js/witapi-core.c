#include <stdlib.h>

#include "ruby.h"
#include "ruby/version.h"

static VALUE rb_eval_string_value_protect_thunk(VALUE str) {
  const ID id_eval = rb_intern("eval");
  VALUE binding = rb_const_get(rb_cObject, rb_intern("TOPLEVEL_BINDING"));
  const VALUE file = rb_utf8_str_new("eval", 4);
  VALUE args[3] = {str, binding, file};
  return rb_funcallv(rb_mKernel, id_eval, 3, args);
}

static VALUE rb_eval_string_value_protect(VALUE str, int *pstate) {
  return rb_protect(rb_eval_string_value_protect_thunk, str, pstate);
}

#define TAG_NONE 0

#include "types.h"

__attribute__((import_module("asyncify"), import_name("start_unwind"))) void
asyncify_start_unwind(void *buf);
#define asyncify_start_unwind(buf)                                             \
  do {                                                                         \
    extern void *rb_asyncify_unwind_buf;                                       \
    rb_asyncify_unwind_buf = (buf);                                            \
    asyncify_start_unwind((buf));                                              \
  } while (0)
__attribute__((import_module("asyncify"), import_name("stop_unwind"))) void
asyncify_stop_unwind(void);
#define asyncify_stop_unwind()                                                 \
  do {                                                                         \
    extern void *rb_asyncify_unwind_buf;                                       \
    rb_asyncify_unwind_buf = NULL;                                             \
    asyncify_stop_unwind();                                                    \
  } while (0)
__attribute__((import_module("asyncify"), import_name("start_rewind"))) void
asyncify_start_rewind(void *buf);
__attribute__((import_module("asyncify"), import_name("stop_rewind"))) void
asyncify_stop_rewind(void);

void *rb_wasm_handle_jmp_unwind(void);
void *rb_wasm_handle_scan_unwind(void);
void *rb_wasm_handle_fiber_unwind(void (**new_fiber_entry)(void *, void *),
                                  void **arg0, void **arg1,
                                  bool *is_new_fiber_started);
#define RB_WASM_ENABLE_DEBUG_LOG 0

#if RB_WASM_ENABLE_DEBUG_LOG
#  define RB_WASM_DEBUG_LOG(...) fprintf(stderr, __VA_ARGS__)
#else
#  define RB_WASM_DEBUG_LOG(...) (void)0
#endif

static bool rb_should_prohibit_rewind = false;

#ifdef JS_ENABLE_COMPONENT_MODEL
void rb_wasm_throw_prohibit_rewind_exception(const char *c_msg,
                                             size_t msg_len) {
  ext_string_t message = {.ptr = (uint8_t *)c_msg, .len = msg_len};
  ruby_js_js_runtime_throw_prohibit_rewind_exception(&message);
}
#else
__attribute__((import_module("rb-js-abi-host"),
               import_name("rb_wasm_throw_prohibit_rewind_exception")))
__attribute__((noreturn)) void
rb_wasm_throw_prohibit_rewind_exception(const char *c_msg, size_t msg_len);
#endif

#define RB_WASM_CHECK_REWIND_PROHIBITED(msg)                                   \
  /*                                                                           \
    If the unwond source and rewinding destination are same, it's acceptable   \
    to rewind even under nested VM operations.                                 \
   */                                                                          \
  if (rb_should_prohibit_rewind &&                                             \
      (asyncify_buf != asyncify_unwound_buf || fiber_entry_point)) {           \
    rb_wasm_throw_prohibit_rewind_exception(msg, sizeof(msg) - 1);             \
  }

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
      void *asyncify_buf = NULL;                                               \
      extern void *rb_asyncify_unwind_buf;                                     \
      void *asyncify_unwound_buf = rb_asyncify_unwind_buf;                     \
      if (asyncify_unwound_buf == NULL)                                        \
        break;                                                                 \
      asyncify_stop_unwind();                                                  \
                                                                               \
      if ((asyncify_buf = rb_wasm_handle_jmp_unwind()) != NULL) {              \
        RB_WASM_CHECK_REWIND_PROHIBITED("rb_wasm_handle_jmp_unwind")           \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      }                                                                        \
      if ((asyncify_buf = rb_wasm_handle_scan_unwind()) != NULL) {             \
        RB_WASM_CHECK_REWIND_PROHIBITED("rb_wasm_handle_scan_unwind")          \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      }                                                                        \
                                                                               \
      asyncify_buf = rb_wasm_handle_fiber_unwind(&fiber_entry_point, &arg0,    \
                                                 &arg1, &new_fiber_started);   \
      if (asyncify_buf) {                                                      \
        RB_WASM_CHECK_REWIND_PROHIBITED("rb_wasm_handle_fiber_unwind")         \
        asyncify_start_rewind(asyncify_buf);                                   \
        continue;                                                              \
      } else if (new_fiber_started) {                                          \
        RB_WASM_CHECK_REWIND_PROHIBITED(                                       \
            "rb_wasm_handle_fiber_unwind but new fiber");                      \
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
      new_args[i] = (char *)((list)->ptr[i].ptr);                              \
    }                                                                          \
  }

static VALUE rb_abi_guest_arena_hash;
static VALUE rb_abi_guest_refcount_hash;

static VALUE rb_abi_lend_object_internal(VALUE obj) {
  VALUE object_id = rb_obj_id(obj);
  VALUE ref_count = rb_hash_lookup(rb_abi_guest_refcount_hash, object_id);
  if (NIL_P(ref_count)) {
    rb_hash_aset(rb_abi_guest_arena_hash, object_id, obj);
    rb_hash_aset(rb_abi_guest_refcount_hash, object_id, INT2FIX(1));
  } else {
    rb_hash_aset(rb_abi_guest_refcount_hash, object_id,
                 INT2FIX(FIX2INT(ref_count) + 1));
  }
  return Qundef;
}
void rb_abi_lend_object(VALUE obj) {
  RB_WASM_DEBUG_LOG("rb_abi_lend_object: obj = %p\n", (void *)obj);
  int state;
  RB_WASM_LIB_RT(rb_protect(rb_abi_lend_object_internal, obj, &state));
  assert(state == TAG_NONE && "rb_abi_lend_object_internal failed");
}

static VALUE rb_abi_guest_rb_abi_value_dtor_internal(VALUE obj) {
  VALUE object_id = rb_obj_id(obj);
  VALUE ref_count = rb_hash_lookup(rb_abi_guest_refcount_hash, object_id);
  if (NIL_P(ref_count)) {
    rb_warning("rb_abi_guest_rb_abi_value_dtor: double free detected");
    return Qundef;
  }
  if (ref_count == INT2FIX(1)) {
    RB_WASM_DEBUG_LOG("rb_abi_guest_rb_abi_value_dtor: ref_count == 1\n");
    rb_hash_delete(rb_abi_guest_refcount_hash, object_id);
    rb_hash_delete(rb_abi_guest_arena_hash, object_id);
  } else {
    RB_WASM_DEBUG_LOG("rb_abi_guest_rb_abi_value_dtor: ref_count = %d\n",
                      FIX2INT(ref_count));
    rb_hash_aset(rb_abi_guest_refcount_hash, object_id,
                 INT2FIX(FIX2INT(ref_count) - 1));
  }
  return Qundef;
}

void rb_abi_guest_rb_abi_value_dtor(void *data) {
  RB_WASM_DEBUG_LOG("rb_abi_guest_rb_abi_value_dtor: data = %p\n", data);
  int state;
  RB_WASM_LIB_RT(
      rb_protect(rb_abi_guest_rb_abi_value_dtor_internal, (VALUE)data, &state));
  assert(state == TAG_NONE && "rb_abi_guest_rb_abi_value_dtor_internal failed");
}

#ifdef JS_ENABLE_COMPONENT_MODEL
void exports_ruby_js_ruby_runtime_rb_iseq_destructor(
    exports_ruby_js_ruby_runtime_rb_iseq_t *rep) {}

void exports_ruby_js_ruby_runtime_rb_abi_value_destructor(
    exports_ruby_js_ruby_runtime_rb_abi_value_t *rep) {
  rb_abi_guest_rb_abi_value_dtor((void *)rep);
}
#endif

// MARK: - Exported functions
// NOTE: Assume that callers always pass null terminated string by
// rb_abi_guest_string_t

void rb_abi_guest_ruby_show_version(void) { ruby_show_version(); }

void rb_abi_guest_ruby_init(void) {
  RB_WASM_LIB_RT(ruby_init())

  rb_abi_guest_arena_hash = rb_hash_new();
  rb_abi_guest_refcount_hash = rb_hash_new();

  rb_gc_register_mark_object(rb_abi_guest_arena_hash);
  rb_gc_register_mark_object(rb_abi_guest_refcount_hash);
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

void rb_abi_guest_ruby_script(rb_abi_guest_string_t *name) {
  RB_WASM_LIB_RT(ruby_script((const char *)name->ptr))
}

void rb_abi_guest_ruby_init_loadpath(void) {
  RB_WASM_LIB_RT(ruby_init_loadpath())
}

void rb_abi_guest_rb_eval_string_protect(
    rb_abi_guest_string_t *str, rb_abi_guest_tuple2_rb_abi_value_s32_t *ret0) {
  VALUE retval;
  RB_WASM_DEBUG_LOG("rb_eval_string_protect: str = %s\n", str->ptr);
  VALUE utf8_str = rb_utf8_str_new((const char *)str->ptr, str->len);
  RB_WASM_LIB_RT(retval = rb_eval_string_value_protect(utf8_str, &ret0->f1));
  RB_WASM_DEBUG_LOG("rb_eval_string_protect: retval = %p, state = %d\n",
                    (void *)retval, ret0->f1);

  if (ret0->f1 == TAG_NONE) {
    rb_abi_lend_object(retval);
  }
  ret0->f0 = rb_abi_guest_rb_abi_value_new((void *)retval);
}

struct rb_funcallv_thunk_ctx {
  VALUE recv;
  ID mid;
  rb_abi_guest_list_rb_abi_value_t *args;
};

VALUE rb_funcallv_thunk(VALUE arg) {
  struct rb_funcallv_thunk_ctx *ctx = (struct rb_funcallv_thunk_ctx *)arg;
  VALUE *c_argv = alloca(sizeof(VALUE) * ctx->args->len);
  for (size_t i = 0; i < ctx->args->len; i++) {
    c_argv[i] = (VALUE)rb_abi_guest_rb_abi_value_get(&ctx->args->ptr[i]);
  }
  return rb_funcallv(ctx->recv, ctx->mid, ctx->args->len, c_argv);
}

void rb_abi_guest_rb_funcallv_protect(
    rb_abi_guest_rb_abi_value_t recv, rb_abi_guest_rb_id_t mid,
    rb_abi_guest_list_rb_abi_value_t *args,
    rb_abi_guest_tuple2_rb_abi_value_s32_t *ret0) {
  VALUE retval;
  VALUE r_recv = (VALUE)rb_abi_guest_rb_abi_value_get(&recv);
  struct rb_funcallv_thunk_ctx ctx = {.recv = r_recv, .mid = mid, .args = args};
  RB_WASM_LIB_RT(retval =
                     rb_protect(rb_funcallv_thunk, (VALUE)&ctx, &ret0->f1));
  RB_WASM_DEBUG_LOG(
      "rb_abi_guest_rb_funcallv_protect: retval = %p, state = %d\n",
      (void *)retval, ret0->f1);

  if (ret0->f1 == TAG_NONE) {
    rb_abi_lend_object(retval);
  }
  ret0->f0 = rb_abi_guest_rb_abi_value_new((void *)retval);
}

rb_abi_guest_rb_id_t rb_abi_guest_rb_intern(rb_abi_guest_string_t *name) {
  return rb_intern((const char *)name->ptr);
}

rb_abi_guest_own_rb_abi_value_t rb_abi_guest_rb_errinfo(void) {
  VALUE retval;
  RB_WASM_LIB_RT(retval = rb_errinfo());
  rb_abi_lend_object(retval);
  return rb_abi_guest_rb_abi_value_new((void *)retval);
}

void rb_abi_guest_rb_clear_errinfo(void) { rb_set_errinfo(Qnil); }

void rb_abi_guest_rstring_ptr(rb_abi_guest_rb_abi_value_t value,
                              rb_abi_guest_string_t *ret0) {
  VALUE r_str = (VALUE)rb_abi_guest_rb_abi_value_get(&value);
  ret0->len = RSTRING_LEN(r_str);
  ret0->ptr = xmalloc(ret0->len);
  memcpy(ret0->ptr, RSTRING_PTR(r_str), ret0->len);
}

uint32_t rb_abi_guest_rb_abi_value_data_ptr(rb_abi_guest_rb_abi_value_t self) {
  VALUE obj = (VALUE)rb_abi_guest_rb_abi_value_get(&self);
  return (uint32_t)DATA_PTR(obj);
}

_Static_assert(RUBY_API_VERSION_MAJOR == 3, "unsupported Ruby version");
#if RUBY_API_VERSION_MINOR == 2
void rb_vm_bugreport(const void *);

void rb_abi_guest_rb_vm_bugreport(void) { rb_vm_bugreport(NULL); }
#elif RUBY_API_VERSION_MINOR >= 3
bool rb_vm_bugreport(const void *, FILE *);

void rb_abi_guest_rb_vm_bugreport(void) { rb_vm_bugreport(NULL, stderr); }
#else
#  error "unsupported Ruby version"
#endif

bool rb_abi_guest_rb_gc_enable(void) { return rb_gc_enable() == Qtrue; }

VALUE rb_gc_disable_no_rest(void);
bool rb_abi_guest_rb_gc_disable(void) {
  // NOTE: rb_gc_disable() is usually preferred to free up memory as much as
  // possible before disabling GC. However it may trigger GC through gc_rest(),
  // and triggering GC having a sandwitched JS frame is unsafe because it misses
  // to mark some living objects in the frames behind the JS frame. So we use
  // rb_gc_disable_no_rest(), which does not trigger GC, instead.
  return rb_gc_disable_no_rest() == Qtrue;
}

bool rb_abi_guest_rb_set_should_prohibit_rewind(bool value) {
  bool old = rb_should_prohibit_rewind;
  rb_should_prohibit_rewind = value;
  return old;
}

static VALUE rb_abi_export_stage = Qnil;
static rb_abi_guest_own_rb_abi_value_t rb_abi_export_rb_value_to_js(void) {
  VALUE staged = rb_abi_export_stage;
  rb_abi_export_stage = Qnil;
  rb_abi_lend_object(staged);
  return rb_abi_guest_rb_abi_value_new((void *)staged);
}

void rb_abi_stage_rb_value_to_js(VALUE value) {
  assert(rb_abi_export_stage == Qnil &&
         "rb_abi_stage_rb_value_to_js: stage is not empty!?");
  rb_abi_export_stage = value;
}

#ifdef JS_ENABLE_COMPONENT_MODEL

extern void __wasm_call_ctors(void);
static inline void __wasm_call_ctors_if_needed(void) {
  static bool __wasm_call_ctors_done = false;
  if (!__wasm_call_ctors_done) {
    __wasm_call_ctors_done = true;
    __wasm_call_ctors();

    // Initialize VFS runtime if it's used
    // NOTE: We don't use wasi-vfs for PIC build. Instead, we use
    // Component Model-native wasi-virt.
#  ifndef __PIC__
    __attribute__((weak)) extern void __wasi_vfs_rt_init(void);
    if (__wasi_vfs_rt_init) {
      __wasi_vfs_rt_init();
    }
#  endif
  }
}

// Exported Functions from `ruby:js/ruby-runtime`
void exports_ruby_js_ruby_runtime_ruby_show_version(void) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_ruby_show_version();
}
void exports_ruby_js_ruby_runtime_ruby_init(void) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_ruby_init();
}
void exports_ruby_js_ruby_runtime_ruby_sysinit(ext_list_string_t *args) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_ruby_sysinit(args);
}
exports_ruby_js_ruby_runtime_own_rb_iseq_t
exports_ruby_js_ruby_runtime_ruby_options(ext_list_string_t *args) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_ruby_options(args);
}
void exports_ruby_js_ruby_runtime_ruby_script(ext_string_t *name) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_ruby_script(name);
}
void exports_ruby_js_ruby_runtime_ruby_init_loadpath(void) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_ruby_init_loadpath();
}
void exports_ruby_js_ruby_runtime_rb_eval_string_protect(
    ext_string_t *str,
    exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t *ret) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_rb_eval_string_protect(str, ret);
}
void exports_ruby_js_ruby_runtime_rb_funcallv_protect(
    exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t recv,
    exports_ruby_js_ruby_runtime_rb_id_t mid,
    exports_ruby_js_ruby_runtime_list_borrow_rb_abi_value_t *args,
    exports_ruby_js_ruby_runtime_tuple2_own_rb_abi_value_s32_t *ret) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_rb_funcallv_protect(recv, mid, args, ret);
}
exports_ruby_js_ruby_runtime_rb_id_t
exports_ruby_js_ruby_runtime_rb_intern(ext_string_t *name) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_rb_intern(name);
}
exports_ruby_js_ruby_runtime_own_rb_abi_value_t
exports_ruby_js_ruby_runtime_rb_errinfo(void) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_rb_errinfo();
}
void exports_ruby_js_ruby_runtime_rb_clear_errinfo(void) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_rb_clear_errinfo();
}
void exports_ruby_js_ruby_runtime_rstring_ptr(
    exports_ruby_js_ruby_runtime_borrow_rb_abi_value_t value,
    ext_string_t *ret) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_rstring_ptr(value, ret);
}
void exports_ruby_js_ruby_runtime_rb_vm_bugreport(void) {
  __wasm_call_ctors_if_needed();
  rb_abi_guest_rb_vm_bugreport();
}
bool exports_ruby_js_ruby_runtime_rb_gc_enable(void) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_rb_gc_enable();
}
bool exports_ruby_js_ruby_runtime_rb_gc_disable(void) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_rb_gc_disable();
}
bool exports_ruby_js_ruby_runtime_rb_set_should_prohibit_rewind(
    bool new_value) {
  __wasm_call_ctors_if_needed();
  return rb_abi_guest_rb_set_should_prohibit_rewind(new_value);
}
exports_ruby_js_ruby_runtime_own_rb_abi_value_t
exports_ruby_js_ruby_runtime_export_rb_value_to_js(void) {
  __wasm_call_ctors_if_needed();
  return rb_abi_export_rb_value_to_js();
}
#endif

void Init_witapi(void) {}
