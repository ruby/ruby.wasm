#include <stdlib.h>
#include "ruby.h"

#include "bindgen/rb-js-abi-guest.h"
#include "bindgen/rb-js-abi-host.h"

__attribute__((import_module("asyncify"), import_name("start_unwind")))
void asyncify_start_unwind(void *buf);
__attribute__((import_module("asyncify"), import_name("stop_unwind")))
void asyncify_stop_unwind(void);
__attribute__((import_module("asyncify"), import_name("start_rewind")))
void asyncify_start_rewind(void *buf);
__attribute__((import_module("asyncify"), import_name("stop_rewind")))
void asyncify_stop_rewind(void);

void *rb_wasm_handle_jmp_unwind(void);
void *rb_wasm_handle_scan_unwind(void);
void *rb_wasm_handle_fiber_unwind(void (**new_fiber_entry)(void *, void *),
                                  void **arg0, void **arg1, bool *is_new_fiber_started);

VALUE rb_wasm_lib_rt(VALUE (main)(void *arg0, void *arg1), void *main_arg0, void *main_arg1) {
  VALUE result;
  void *asyncify_buf;

  bool new_fiber_started = false;
  void *arg0 = NULL, *arg1 = NULL;
  void (*fiber_entry_point)(void *, void *) = NULL;

  while (1) {
    if (fiber_entry_point) {
      fiber_entry_point(arg0, arg1);
    } else {
      result = main(main_arg0, main_arg1);
    }

    // NOTE: it's important to call 'asyncify_stop_unwind' here instead in rb_wasm_handle_jmp_unwind
    // because unless that, Asyncify inserts another unwind check here and it unwinds to the root frame.
    asyncify_stop_unwind();

    if ((asyncify_buf = rb_wasm_handle_jmp_unwind()) != NULL) {
      asyncify_start_rewind(asyncify_buf);
      continue;
    }
    if ((asyncify_buf = rb_wasm_handle_scan_unwind()) != NULL) {
      asyncify_start_rewind(asyncify_buf);
      continue;
    }

    asyncify_buf = rb_wasm_handle_fiber_unwind(&fiber_entry_point, &arg0, &arg1, &new_fiber_started);
    // Newly starting fiber doesn't have asyncify buffer yet, so don't rewind it for the first time entry
    if (asyncify_buf) {
      asyncify_start_rewind(asyncify_buf);
      continue;
    } else if (new_fiber_started) {
      continue;
    }

    break;
  }
  return result;
}


// MARK: - Exported functions
// NOTE: Assume that callers always pass null terminated string by rb_js_abi_guest_string_t

static VALUE ruby_init_thunk(void *arg0, void *arg1) {
  ruby_init();
  return Qnil;
}
void rb_js_abi_guest_ruby_init(void) {
  rb_wasm_lib_rt(ruby_init_thunk, NULL, NULL);
}
rb_js_abi_guest_rb_iseq_t rb_js_abi_guest_ruby_options(rb_js_abi_guest_list_string_t *args) {
  return rb_js_abi_guest_rb_iseq_new(ruby_options(args->len, (char **)args->ptr));
}
rb_js_abi_guest_errno_t rb_js_abi_guest_ruby_run_node(rb_js_abi_guest_rb_iseq_t node) {
  return ruby_run_node(rb_js_abi_guest_rb_iseq_get(&node));
}
void rb_js_abi_guest_ruby_script(rb_js_abi_guest_string_t *name) {
  ruby_script(name->ptr);
}
void rb_js_abi_guest_ruby_init_loadpath(void) {
  ruby_init_loadpath();
}

static VALUE rb_eval_string_thunk(void *arg0, void *arg1) {
  return rb_eval_string(arg0);
}
rb_js_abi_guest_rb_value_t rb_js_abi_guest_rb_eval_string(rb_js_abi_guest_string_t *str) {
  return rb_wasm_lib_rt(rb_eval_string_thunk, str->ptr, NULL);
}

// MARK: - Ruby extension

static VALUE rb_mJS;

static VALUE _rb_js_eval_js(VALUE _, VALUE code_str) {
  const char *code_str_ptr = (const char *)RSTRING_PTR(code_str);
  rb_js_abi_host_string_t abi_str;
  rb_js_abi_host_string_set(&abi_str, code_str_ptr);
  rb_js_abi_host_eval_js(&abi_str);
  return Qnil;
}

void
Init_js(void)
{
  rb_mJS = rb_define_module("JS");
  VALUE rb_mABI = rb_define_class_under(rb_mJS, "ABI", rb_cObject);

  rb_define_module_function(rb_mABI, "eval_js", _rb_js_eval_js, 1);
}
