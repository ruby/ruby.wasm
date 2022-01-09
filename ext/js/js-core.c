#include <stdlib.h>

#include "ruby.h"

#include "bindgen/rb-js-abi-host.h"

// MARK: - Ruby extension

#ifndef RBOOL
#define RBOOL(v) ((v) ? Qtrue : Qfalse)
#endif

extern VALUE rb_mKernel;

static VALUE rb_mJS;
static VALUE rb_mJS_Object;

static ID i_to_js;

struct jsvalue {
  rb_js_abi_host_js_value_t abi;
};

static void jsvalue_mark(void *p) {}

static void jsvalue_free(void *p) {
  struct jsvalue *ptr = p;
  ruby_xfree(ptr);
}

static size_t jsvalue_memsize(const void *p) { return sizeof(struct jsvalue); }

static const rb_data_type_t jsvalue_data_type = {"jsvalue",
                                                 {
                                                     jsvalue_mark,
                                                     jsvalue_free,
                                                     jsvalue_memsize,
                                                 },
                                                 0,
                                                 0,
                                                 RUBY_TYPED_FREE_IMMEDIATELY};
static VALUE jsvalue_s_allocate(VALUE klass) {
  struct jsvalue *p;
  VALUE obj =
      TypedData_Make_Struct(klass, struct jsvalue, &jsvalue_data_type, p);
  return obj;
}

static VALUE jsvalue_s_new(rb_js_abi_host_js_value_t abi) {
  struct jsvalue *p;
  VALUE obj = TypedData_Make_Struct(rb_mJS_Object, struct jsvalue,
                                    &jsvalue_data_type, p);
  p->abi = abi;
  return obj;
}

static struct jsvalue *check_jsvalue(VALUE obj) {
  return rb_check_typeddata(obj, &jsvalue_data_type);
}

#define IS_JSVALUE(obj) (rb_typeddata_is_kind_of((obj), &jsvalue_data_type))

static VALUE _rb_js_eval_js(VALUE _, VALUE code_str) {
  const char *code_str_ptr = (const char *)RSTRING_PTR(code_str);
  rb_js_abi_host_string_t abi_str;
  rb_js_abi_host_string_set(&abi_str, code_str_ptr);
  rb_js_abi_host_eval_js(&abi_str);
  return Qnil;
}

static VALUE _rb_js_is_js(VALUE _, VALUE obj) {
  if (!IS_JSVALUE(obj)) {
    return Qfalse;
  }
  struct jsvalue *val = DATA_PTR(obj);
  return RBOOL(rb_js_abi_host_is_js(val->abi));
}

VALUE _rb_js_try_convert(VALUE klass, VALUE obj, VALUE _default) {
  if (_rb_js_is_js(klass, obj)) {
    return obj;
  } else if (rb_respond_to(obj, i_to_js)) {
    return rb_funcallv(obj, i_to_js, 0, NULL);
  } else {
    return _default;
  }
}

static VALUE _rb_js_is_kind_of(VALUE klass, VALUE obj, VALUE c) {
  if (!IS_JSVALUE(obj)) {
    return Qfalse;
  }
  struct jsvalue *val = DATA_PTR(obj);
  VALUE js_klass_v = _rb_js_try_convert(klass, c, Qnil);
  struct jsvalue *js_klass = DATA_PTR(js_klass_v);
  return RBOOL(rb_js_abi_host_instance_of(val->abi, js_klass->abi));
}

static VALUE _rb_js_global_this(VALUE _) {
  return jsvalue_s_new(rb_js_abi_host_global_this());
}

static VALUE _rb_js_obj_aref(VALUE obj, VALUE key) {
  struct jsvalue *p = check_jsvalue(obj);
  key = rb_obj_as_string(key);
  const char *key_cstr = (const char *)RSTRING_PTR(key);
  rb_js_abi_host_string_t key_abi_str;
  rb_js_abi_host_string_dup(&key_abi_str, key_cstr);
  return jsvalue_s_new(rb_js_abi_host_reflect_get(p->abi, &key_abi_str));
}

static VALUE _rb_js_obj_aset(VALUE obj, VALUE key, VALUE val) {
  struct jsvalue *p = check_jsvalue(obj);
  struct jsvalue *v = check_jsvalue(val);
  key = rb_obj_as_string(key);
  const char *key_cstr = (const char *)RSTRING_PTR(key);
  rb_js_abi_host_string_t key_abi_str;
  rb_js_abi_host_string_dup(&key_abi_str, key_cstr);
  rb_js_abi_host_reflect_set(p->abi, &key_abi_str, v->abi);
  return val;
}

// workaround to transfer js value to js by using wit.
// wit doesn't allow to communicate a resource to guest and host for now.
static VALUE _rb_js_export_to_js(VALUE obj) {
  struct jsvalue *p = check_jsvalue(obj);
  rb_js_abi_host_take_js_value(p->abi);
  return Qnil;
}

void Init_js() {
  rb_mJS = rb_define_module("JS");
  rb_define_module_function(rb_mJS, "is_a?", _rb_js_is_kind_of, 2);
  rb_define_module_function(rb_mJS, "try_convert", _rb_js_try_convert, 2);
  rb_define_module_function(rb_mJS, "eval", _rb_js_eval_js, 1);
  rb_define_module_function(rb_mJS, "global", _rb_js_global_this, 0);

  rb_define_module_function(rb_mKernel, "js?", _rb_js_is_js, 1);

  i_to_js = rb_intern("to_js");
  rb_mJS_Object = rb_define_class_under(rb_mJS, "Object", rb_cObject);
  rb_define_alloc_func(rb_mJS_Object, jsvalue_s_allocate);
  rb_define_method(rb_mJS_Object, "[]", _rb_js_obj_aref, 1);
  rb_define_method(rb_mJS_Object, "[]=", _rb_js_obj_aset, 2);
  rb_define_method(rb_mJS_Object, "__export_to_js", _rb_js_export_to_js, 0);
}
