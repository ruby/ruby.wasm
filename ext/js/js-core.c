#include <stdlib.h>

#include "ruby.h"

#include "bindgen/rb-js-abi-host.h"

// MARK: - Ruby extension

#ifndef RBOOL
#  define RBOOL(v) ((v) ? Qtrue : Qfalse)
#endif

extern VALUE rb_mKernel;
extern VALUE rb_cInteger;
extern VALUE rb_cString;
extern VALUE rb_cTrueClass;
extern VALUE rb_cFalseClass;
extern VALUE rb_cProc;

// from js/js-core.c
void rb_abi_lend_object(VALUE obj);

static VALUE rb_mJS;
static VALUE rb_cJS_Object;

static ID i_to_js;

struct jsvalue {
  rb_js_abi_host_js_abi_value_t abi;
};

static void jsvalue_mark(void *p) {}

static void jsvalue_free(void *p) {
  struct jsvalue *ptr = p;
  rb_js_abi_host_js_abi_value_free(&ptr->abi);
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

static VALUE jsvalue_s_new(rb_js_abi_host_js_abi_value_t abi) {
  struct jsvalue *p;
  VALUE obj = TypedData_Make_Struct(rb_cJS_Object, struct jsvalue,
                                    &jsvalue_data_type, p);
  p->abi = abi;
  return obj;
}

static struct jsvalue *check_jsvalue(VALUE obj) {
  return rb_check_typeddata(obj, &jsvalue_data_type);
}

#define IS_JSVALUE(obj) (rb_typeddata_is_kind_of((obj), &jsvalue_data_type))

static inline void rstring_to_abi_string(VALUE rstr,
                                         rb_js_abi_host_string_t *abi_str) {
  abi_str->len = RSTRING_LEN(rstr);
  abi_str->ptr = xmalloc(abi_str->len);
  memcpy(abi_str->ptr, RSTRING_PTR(rstr), abi_str->len);
}

/*
 * call-seq:
 *   JS.eval(code) -> JS::Object
 *
 *  Evaluates the given JavaScript code, returning the result as a JS::Object.
 *
 *   p JS.eval("return 1 + 1").to_i                             # => 2
 *   p JS.eval("return new Object()").is_a?(JS.global[:Object]) # => true
 */
static VALUE _rb_js_eval_js(VALUE _, VALUE code_str) {
  rb_js_abi_host_string_t abi_str;
  rstring_to_abi_string(code_str, &abi_str);
  return jsvalue_s_new(rb_js_abi_host_eval_js(&abi_str));
}

static VALUE _rb_js_is_js(VALUE _, VALUE obj) {
  if (!IS_JSVALUE(obj)) {
    return Qfalse;
  }
  struct jsvalue *val = DATA_PTR(obj);
  return RBOOL(rb_js_abi_host_is_js(val->abi));
}

/*
 * call-seq:
 *   JS.try_convert(obj) -> JS::Object or nil
 *
 *  Try to convert the given object to a JS::Object using <code>to_js</code>
 *  method. Returns <code>nil</code> if the object cannot be converted.
 *
 *   p JS.try_convert(1)                           # => JS::Object
 *   p JS.try_convert("foo")                       # => JS::Object
 *   p JS.try_convert(Object.new)                  # => nil
 *   p JS.try_convert(JS::Object.wrap(Object.new)) # => JS::Object
 */
VALUE _rb_js_try_convert(VALUE klass, VALUE obj) {
  if (_rb_js_is_js(klass, obj)) {
    return obj;
  } else if (rb_respond_to(obj, i_to_js)) {
    return rb_funcallv(obj, i_to_js, 0, NULL);
  } else {
    return Qnil;
  }
}

/*
 * call-seq:
 *   JS.is_a?(js_obj, js_class) -> true or false
 *
 *  Returns <code>true</code> if <i>js_class</i> is the instance of
 *  <i>js_obj</i>, otherwise returns <code>false</code>.
 *  Comparison is done using the <code>instanceof</code> in JavaScript.
 *
 *   p JS.is_a?(JS.global, JS.global[:Object]) #=> true
 *   p JS.is_a?(JS.global, Object)             #=> false
 */
static VALUE _rb_js_is_kind_of(VALUE klass, VALUE obj, VALUE c) {
  if (!IS_JSVALUE(obj)) {
    return Qfalse;
  }
  struct jsvalue *val = DATA_PTR(obj);
  VALUE js_klass_v = _rb_js_try_convert(klass, c);
  struct jsvalue *js_klass = DATA_PTR(js_klass_v);
  return RBOOL(rb_js_abi_host_instance_of(val->abi, js_klass->abi));
}

/*
 * call-seq:
 *   JS.global -> JS::Object
 *
 *  Returns <code>globalThis</code> JavaScript object.
 *
 *   p JS.global
 *   p JS.global[:document]
 */
static VALUE _rb_js_global_this(VALUE _) {
  return jsvalue_s_new(rb_js_abi_host_global_this());
}

/*
 * call-seq:
 *   self[prop] -> JS::Object
 *
 * Returns the value of the property:
 *   JS.global[:Object]
 *   JS.global[:console][:log]
 */
static VALUE _rb_js_obj_aref(VALUE obj, VALUE key) {
  struct jsvalue *p = check_jsvalue(obj);
  rb_js_abi_host_string_t key_abi_str;
  key = rb_obj_as_string(key);
  rstring_to_abi_string(key, &key_abi_str);
  return jsvalue_s_new(rb_js_abi_host_reflect_get(p->abi, &key_abi_str));
}

/*
 * call-seq:
 *   self[prop] = value -> JS::Object
 *
 * Set a property on the object with the given value.
 * Returns the value of the property:
 *   JS.global[:Object][:foo] = "bar"
 *   p JS.global[:console][:foo] # => "bar"
 */
static VALUE _rb_js_obj_aset(VALUE obj, VALUE key, VALUE val) {
  struct jsvalue *p = check_jsvalue(obj);
  struct jsvalue *v = check_jsvalue(_rb_js_try_convert(rb_mJS, val));
  rb_js_abi_host_string_t key_abi_str;
  key = rb_obj_as_string(key);
  rstring_to_abi_string(key, &key_abi_str);
  rb_js_abi_host_reflect_set(p->abi, &key_abi_str, v->abi);
  return val;
}

/*
 * call-seq:
 *   js_value.strictly_eql?(other) -> boolean
 *
 * Performs "===" comparison, a.k.a the "Strict Equality Comparison"
 * algorithm defined in the ECMAScript.
 * https://262.ecma-international.org/11.0/#sec-strict-equality-comparison
 */
static VALUE _rb_js_obj_strictly_eql(VALUE obj, VALUE other) {
  struct jsvalue *lhs = check_jsvalue(obj);
  struct jsvalue *rhs = check_jsvalue(other);
  bool result = rb_js_abi_host_js_value_strictly_equal(lhs->abi, rhs->abi);
  return RBOOL(result);
}

/*
 * call-seq:
 *   js_value.==(other) -> boolean
 *   js_value.eql?(other) -> boolean
 *
 * Performs "==" comparison, a.k.a the "Abstract Equality Comparison"
 * algorithm defined in the ECMAScript.
 * https://262.ecma-international.org/11.0/#sec-abstract-equality-comparison
 */
static VALUE _rb_js_obj_eql(VALUE obj, VALUE other) {
  struct jsvalue *lhs = check_jsvalue(obj);
  struct jsvalue *rhs = check_jsvalue(other);
  bool result = rb_js_abi_host_js_value_equal(lhs->abi, rhs->abi);
  return RBOOL(result);
}

/*
 * :nodoc: all
 */
static VALUE _rb_js_obj_hash(VALUE obj) {
  // TODO(katei): Track the JS object id in JS side as Pyodide and Swift JavaScriptKit do.
  return Qnil;
}

/*
 * call-seq:
 *   js_value.call(name, *args) -> JS::Object
 *
 * Call a JavaScript method specified by the name with the arguments.
 * Returns the result of the call as a JS::Object.
 *   p JS.global.call(:parseInt, JS.eval("return '42'"))    # => 42
 *   JS.global[:console].call(:log, JS.eval("return '42'")) # => undefined
 */
static VALUE _rb_js_obj_call(int argc, VALUE *argv, VALUE obj) {
  struct jsvalue *p = check_jsvalue(obj);
  if (argc == 0) {
    rb_raise(rb_eArgError, "no method name given");
  }
  VALUE method = _rb_js_obj_aref(obj, argv[0]);
  struct jsvalue *abi_method = check_jsvalue(method);

  rb_js_abi_host_list_js_abi_value_t abi_args;
  int function_arguments_count = argc;
  if(!rb_block_given_p())
    function_arguments_count -= 1;

  abi_args.ptr = ALLOCA_N(rb_js_abi_host_js_abi_value_t, function_arguments_count);
  abi_args.len = function_arguments_count;
  for (int i = 1; i < argc; i++) {
    VALUE arg = _rb_js_try_convert(rb_mJS, argv[i]);
    if (arg == Qnil) {
      rb_raise(rb_eTypeError, "argument %d is not a JS::Object like object",
               1 + i);
    }
    abi_args.ptr[i - 1] = check_jsvalue(arg)->abi;
  }

  if(rb_block_given_p()) {
    VALUE proc = rb_block_proc();
    abi_args.ptr[function_arguments_count - 1] = check_jsvalue(_rb_js_try_convert(rb_mJS, proc))->abi;
  }

  return jsvalue_s_new(
      rb_js_abi_host_reflect_apply(abi_method->abi, p->abi, &abi_args));
}

/*
 * call-seq:
 *  js_value.typeof -> String
 *
 * Returns the result string of JavaScript 'typeof' operator.
 * See also JS.is_a? for 'instanceof' operator.
 *   p JS.global.typeof                     # => "object"
 *   p JS.eval("return 1").typeof           # => "number"
 *   p JS.eval("return 'str'").typeof       # => "string"
 *   p JS.eval("return undefined").typeof   # => "undefined"
 *   p JS.eval("return null").typeof        # => "object"
 */
static VALUE _rb_js_obj_typeof(VALUE obj) {
  struct jsvalue *p = check_jsvalue(obj);
  rb_js_abi_host_string_t ret0;
  rb_js_abi_host_js_value_typeof(p->abi, &ret0);
  return rb_str_new(ret0.ptr, ret0.len);
}

/*
 * call-seq:
 *   inspect -> string
 *
 *  Returns a printable version of +self+:
 *   p JS.global # => [object global]
 */
static VALUE _rb_js_obj_inspect(VALUE obj) {
  struct jsvalue *p = check_jsvalue(obj);
  rb_js_abi_host_string_t ret0;
  rb_js_abi_host_js_value_to_string(p->abi, &ret0);
  return rb_str_new(ret0.ptr, ret0.len);
}

/*
 * :nodoc: all
 * workaround to transfer js value to js by using wit.
 * wit doesn't allow to communicate a resource to guest and host for now.
 */
static VALUE _rb_js_export_to_js(VALUE obj) {
  struct jsvalue *p = check_jsvalue(obj);
  rb_js_abi_host_export_js_value_to_host(p->abi);
  return Qnil;
}

static VALUE _rb_js_import_from_js(VALUE obj) {
  return jsvalue_s_new(rb_js_abi_host_import_js_value_from_host());
}

/*
 * call-seq:
 *   JS::Object.wrap(obj) -> JS::Object
 *
 *  Returns +obj+ wrapped by JS class RbValue.
 */
static VALUE _rb_js_obj_wrap(VALUE obj, VALUE wrapping) {
  rb_abi_lend_object(wrapping);
  return jsvalue_s_new(rb_js_abi_host_rb_object_to_js_rb_value((uint32_t)wrapping));
}

/*
 * call-seq:
 *   to_js -> JS::Object
 *
 *  Returns +self+ as a JS::Object.
 */
static VALUE _rb_js_integer_to_js(VALUE obj) {
  if (FIXNUM_P(obj)) {
    return jsvalue_s_new(rb_js_abi_host_int_to_js_number(FIX2LONG(obj)));
  } else {
    rb_raise(rb_eTypeError, "can't convert Bignum to JS::Object");
  }
}

/*
 * call-seq:
 *   to_js -> JS::Object
 *
 *  Returns +self+ as a JS::Object.
 */
static VALUE _rb_js_string_to_js(VALUE obj) {
  rb_js_abi_host_string_t abi_str;
  rstring_to_abi_string(obj, &abi_str);
  return jsvalue_s_new(rb_js_abi_host_string_to_js_string(&abi_str));
}

/*
 * call-seq:
 *   to_js -> JS::Object
 *
 *  Returns +self+ as a JS::Object.
 */
static VALUE _rb_js_true_to_js(VALUE obj) {
  return jsvalue_s_new(rb_js_abi_host_bool_to_js_bool(true));
}

/*
 * call-seq:
 *   to_js -> JS::Object
 *
 *  Returns +self+ as a JS::Object.
 */
static VALUE _rb_js_false_to_js(VALUE obj) {
  return jsvalue_s_new(rb_js_abi_host_bool_to_js_bool(false));
}

/*
 * call-seq:
 *   to_js -> JS::Object
 *
 *  Returns +self+ as a JS::Object.
 */
static VALUE _rb_js_proc_to_js(VALUE obj) {
  rb_abi_lend_object(obj);
  return jsvalue_s_new(rb_js_abi_host_proc_to_js_function((uint32_t) obj));
}

/*
 * JavaScript interoperations module
 */
void Init_js() {
  rb_mJS = rb_define_module("JS");
  rb_define_module_function(rb_mJS, "is_a?", _rb_js_is_kind_of, 2);
  rb_define_module_function(rb_mJS, "try_convert", _rb_js_try_convert, 1);
  rb_define_module_function(rb_mJS, "eval", _rb_js_eval_js, 1);
  rb_define_module_function(rb_mJS, "global", _rb_js_global_this, 0);

  i_to_js = rb_intern("to_js");
  rb_cJS_Object = rb_define_class_under(rb_mJS, "Object", rb_cObject);
  rb_define_alloc_func(rb_cJS_Object, jsvalue_s_allocate);
  rb_define_method(rb_cJS_Object, "[]", _rb_js_obj_aref, 1);
  rb_define_method(rb_cJS_Object, "[]=", _rb_js_obj_aset, 2);
  rb_define_method(rb_cJS_Object, "strictly_eql?", _rb_js_obj_strictly_eql, 1);
  rb_define_method(rb_cJS_Object, "eql?", _rb_js_obj_eql, 1);
  rb_define_method(rb_cJS_Object, "==", _rb_js_obj_eql, 1);
  rb_define_method(rb_cJS_Object, "hash", _rb_js_obj_hash, 0);
  rb_define_method(rb_cJS_Object, "call", _rb_js_obj_call, -1);
  rb_define_method(rb_cJS_Object, "typeof", _rb_js_obj_typeof, 0);
  rb_define_method(rb_cJS_Object, "__export_to_js", _rb_js_export_to_js, 0);
  rb_define_singleton_method(rb_cJS_Object, "__import_from_js", _rb_js_import_from_js, 0);
  rb_define_method(rb_cJS_Object, "inspect", _rb_js_obj_inspect, 0);
  rb_define_method(rb_cJS_Object, "to_s", _rb_js_obj_inspect, 0);
  rb_define_singleton_method(rb_cJS_Object, "wrap", _rb_js_obj_wrap, 1);

  rb_define_method(rb_cInteger, "to_js", _rb_js_integer_to_js, 0);
  rb_define_method(rb_cString, "to_js", _rb_js_string_to_js, 0);
  rb_define_method(rb_cTrueClass, "to_js", _rb_js_true_to_js, 0);
  rb_define_method(rb_cFalseClass, "to_js", _rb_js_false_to_js, 0);
  rb_define_method(rb_cProc, "to_js", _rb_js_proc_to_js, 0);
}
