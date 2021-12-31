#include <stdlib.h>
#include "ruby.h"

#include "bindgen/rb-js-abi-guest.h"
#include "bindgen/rb-js-abi-host.h"

// MARK: - Exported functions
// NOTE: Assume that callers always pass null terminated string by rb_js_abi_guest_string_t

void rb_js_abi_guest_ruby_init(void) {
  ruby_init();
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
rb_js_abi_guest_rb_value_t rb_js_abi_guest_rb_eval_string(rb_js_abi_guest_string_t *str) {
  return rb_js_abi_guest_rb_value_new((void *)rb_eval_string(str->ptr));
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
