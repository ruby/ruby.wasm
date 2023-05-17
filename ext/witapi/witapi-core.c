#include <stdlib.h>

#include "ruby.h"

// ========= Private Ruby API =========
// from eval_intern.h
VALUE rb_f_eval(int argc, const VALUE *argv, VALUE self);
// from internal/vm.h
PUREFUNC(VALUE rb_vm_top_self(void));
// from vm_core.h
typedef struct rb_control_frame_struct {
  const VALUE *pc;  /* cfp[0] */
  VALUE *sp;        /* cfp[1] */
  const void *iseq; /* cfp[2] */
  VALUE self;       /* cfp[3] / block[0] */
  const VALUE *ep;  /* cfp[4] / block[1] */
} rb_control_frame_t;

typedef struct rb_execution_context_struct {
  /* execution information */
  VALUE *vm_stack;      /* must free, must mark */
  size_t vm_stack_size; /* size in word (byte size / sizeof(VALUE)) */
  rb_control_frame_t *cfp;
} rb_execution_context_t;

// from vm.c and vm_core.h
RUBY_EXTERN struct rb_execution_context_struct *ruby_current_ec;
#define GET_EC() (ruby_current_ec)
rb_control_frame_t *
rb_vm_get_ruby_level_next_cfp(const rb_execution_context_t *ec,
                              const rb_control_frame_t *cfp);
// ====== End of Private Ruby API =====

VALUE
ruby_eval_string_value_from_file(VALUE str, VALUE file) {
  rb_execution_context_t *ec = GET_EC();
  rb_control_frame_t *cfp =
      ec ? rb_vm_get_ruby_level_next_cfp(ec, ec->cfp) : NULL;
  VALUE self = cfp ? cfp->self : rb_vm_top_self();
#define argc 4
  const VALUE argv[argc] = {str, Qnil, file, INT2FIX(1)};
  return rb_f_eval(argc, argv, self);
#undef argc
}

static VALUE rb_eval_string_value_protect_thunk(VALUE str) {
  return ruby_eval_string_value_from_file(str, rb_utf8_str_new("eval", 4));
}

// TODO(katei): This API should be moved to CRuby itself.
VALUE
rb_eval_string_value_protect(VALUE str, int *pstate) {
  return rb_protect(rb_eval_string_value_protect_thunk, str, pstate);
}

#define TAG_NONE 0

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
#define RB_WASM_ENABLE_DEBUG_LOG 0

#if RB_WASM_ENABLE_DEBUG_LOG
#  define RB_WASM_DEBUG_LOG(...) fprintf(stderr, __VA_ARGS__)
#else
#  define RB_WASM_DEBUG_LOG(...) (void)0
#endif

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

void rb_abi_guest_rb_eval_string_protect(
    rb_abi_guest_string_t *str, rb_abi_guest_tuple2_rb_abi_value_s32_t *ret0) {
  VALUE retval;
  RB_WASM_DEBUG_LOG("rb_eval_string_protect: str = %s\n", str->ptr);
  VALUE utf8_str = rb_utf8_str_new(str->ptr, str->len);
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
  return rb_intern(name->ptr);
}

rb_abi_guest_rb_abi_value_t rb_abi_guest_rb_errinfo(void) {
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

void rb_vm_bugreport(const void *);

void rb_abi_guest_rb_vm_bugreport(void) { rb_vm_bugreport(NULL); }

void Init_witapi(void) {}
