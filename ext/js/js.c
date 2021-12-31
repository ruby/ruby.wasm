#include <stdlib.h>
#include "ruby.h"

#define EXPORT_SYMBOL(name) __attribute__((export_name(name)))

#define IMPORT_SYMBOL(name, func) \
  __attribute__((__import_module__("rb_js_abi"), __import_name__(name))) func;

EXPORT_SYMBOL("ruby_init") void rb_js_abi_ruby_init(void) {
  ruby_init();
}
EXPORT_SYMBOL("ruby_options") void *rb_js_abi_ruby_options(int argc, char **argv) {
  return ruby_options(argc, argv);
}
EXPORT_SYMBOL("ruby_run_node") int rb_js_abi_ruby_run_node(void *n) {
  return ruby_run_node(n);
}
EXPORT_SYMBOL("ruby_script") void rb_js_abi_ruby_script(const char *name) {
  ruby_script(name);
}
EXPORT_SYMBOL("ruby_init_loadpath") void rb_js_abi_ruby_init_loadpath(void) {
  ruby_init_loadpath();
}
EXPORT_SYMBOL("rb_eval_string") VALUE rb_js_abi_rb_eval_string(const char *str) {
  return rb_eval_string(str);
}
IMPORT_SYMBOL("eval_js", void _rb_js_abi_eval_js(const char *code);)

static VALUE rb_mJS;

static VALUE _rb_js_eval_js(VALUE _, VALUE code_str) {
  const char *code_str_ptr = (const char *)RSTRING_PTR(code_str);
  _rb_js_abi_eval_js(code_str_ptr);
  return Qnil;
}

void
Init_js(void)
{
  rb_mJS = rb_define_module("JS");
  VALUE rb_mABI = rb_define_class_under(rb_mJS, "ABI", rb_cObject);

  rb_define_module_function(rb_mABI, "eval_js", _rb_js_eval_js, 1);
}
