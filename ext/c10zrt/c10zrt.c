
#include "ruby.h"
#include <stdbool.h>

extern void __wasm_call_ctors(void);
extern void __wasm_call_dtors(void);

static void *initialized_iseq;

int rb_wasm_rt_start(int(main)(int argc, char **argv), int argc, char **argv);
static int wizer_initialize_internal(int argc, char **argv) {
  ruby_sysinit(&argc, &argv);
  ruby_init();
  initialized_iseq = ruby_options(argc, argv);
  return 0;
}

#include <dirent.h>

void debug_dump_fs_tree(const char *path) {
  // Dump the file system tree for debugging purposes like `tree` command using
  // libc's dirent.h

  DIR *dir = opendir(path);
  if (dir == NULL) {
    printf("Failed to open directory: %s\n", path);
    return;
  }
  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (entry->d_type == DT_DIR) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
        continue;
      }
      printf("%s/%s\n", path, entry->d_name);
      char *subpath = malloc(strlen(path) + strlen(entry->d_name) + 2);
      sprintf(subpath, "%s/%s", path, entry->d_name);
      debug_dump_fs_tree(subpath);
      free(subpath);
    } else {
      printf("%s/%s\n", path, entry->d_name);
    }
  }
}

__attribute__((export_name("ruby.wizer.initialize"))) void
__ruby_wizer_initialize() {
  __wasm_call_ctors();

  debug_dump_fs_tree("/exe");
  int err;
  size_t argc;
  size_t argv_buf_size;
  err = __wasi_args_sizes_get(&argc, &argv_buf_size);
  if (err != 0) {
    __wasi_proc_exit(err);
  }
  char *argv_buf = malloc(argv_buf_size);
  if (argv_buf == NULL) {
    __wasi_proc_exit(__WASI_ERRNO_NOMEM);
  }
  char **argv = malloc(argc * sizeof(char *));
  if (argv == NULL) {
    __wasi_proc_exit(__WASI_ERRNO_NOMEM);
  }
  err = __wasi_args_get((uint8_t **)argv, (uint8_t *)argv_buf);
  if (err != 0) {
    __wasi_proc_exit(err);
  }
  rb_wasm_rt_start(wizer_initialize_internal, argc, argv);
}

static int wizer_run_internal(int argc, char **argv) {
  return ruby_run_node(initialized_iseq);
}

__attribute__((export_name("ruby.wizer.resume"))) void __ruby_wizer_resume() {
  int ret = rb_wasm_rt_start(wizer_run_internal, 0, NULL);
  __wasm_call_dtors();
  if (ret != 0) {
    __wasi_proc_exit(ret);
  }
}

VALUE rb_mWaddle;

typedef struct {
  const char *module_name;
  const char *name;
  void *func;
} import_func_entry;

static size_t import_funcs_size = 0;
static import_func_entry *import_funcs;

__attribute__((export_name("ruby.c10zrt.add_import_func"))) void
ruby_c10zrt_add_import_func(const char *module_name, const char *name,
                            void *func) {
  static size_t import_funcs_capacity = 0;
  if (import_funcs_capacity == 0) {
    import_funcs_capacity = 16;
    import_funcs = malloc(import_funcs_capacity * sizeof(import_func_entry));
  } else if (import_funcs_size == import_funcs_capacity) {
    import_funcs_capacity *= 2;
    import_funcs = realloc(import_funcs,
                           import_funcs_capacity * sizeof(import_func_entry));
  }
  import_funcs[import_funcs_size].module_name = module_name;
  import_funcs[import_funcs_size].name = name;
  import_funcs[import_funcs_size].func = func;
  import_funcs_size++;
}

static import_func_entry *find_import_func(const char *module_name,
                                           const char *name) {
  for (size_t i = 0; i < import_funcs_size; i++) {
    if (strcmp(import_funcs[i].module_name, module_name) == 0 &&
        strcmp(import_funcs[i].name, name) == 0) {
      return &import_funcs[i];
    }
  }
  return NULL;
}

__attribute__((export_name("ruby.c10zrt.init_context"))) VALUE
ruby_c10zrt_init_context(void) {
  return rb_ary_new();
}

__attribute__((export_name("ruby.c10zrt.call_export_func"))) void
ruby_c10zrt_call_export_func(const char *name, VALUE ctx) {
  VALUE func = rb_funcall(rb_mWaddle, rb_intern("export_func"), 1,
                          rb_str_new_cstr(name));
  rb_funcall(func, rb_intern("call"), 1, ctx);
}

__attribute__((export_name("ruby.c10zrt.push_i32"))) void
ruby_c10zrt_push_i32(int32_t value, VALUE ctx) {
  rb_ary_push(ctx, INT2NUM(value));
}

__attribute__((export_name("ruby.c10zrt.push_i64"))) void
ruby_c10zrt_push_i64(int64_t value, VALUE ctx) {
  rb_ary_push(ctx, LL2NUM(value));
}

__attribute__((export_name("ruby.c10zrt.push_f32"))) void
ruby_c10zrt_push_f32(float value, VALUE ctx) {
  rb_ary_push(ctx, DBL2NUM(value));
}

__attribute__((export_name("ruby.c10zrt.push_f64"))) void
ruby_c10zrt_push_f64(double value, VALUE ctx) {
  rb_ary_push(ctx, DBL2NUM(value));
}

__attribute__((export_name("ruby.c10zrt.pop_i32"))) int32_t
ruby_c10zrt_pop_i32(VALUE ctx) {
  return NUM2INT(rb_ary_pop(ctx));
}

__attribute__((export_name("ruby.c10zrt.pop_i64"))) int64_t
ruby_c10zrt_pop_i64(VALUE ctx) {
  return NUM2LL(rb_ary_pop(ctx));
}

__attribute__((export_name("ruby.c10zrt.pop_f32"))) float
ruby_c10zrt_pop_f32(VALUE ctx) {
  return NUM2DBL(rb_ary_pop(ctx));
}

__attribute__((export_name("ruby.c10zrt.pop_f64"))) double
ruby_c10zrt_pop_f64(VALUE ctx) {
  return NUM2DBL(rb_ary_pop(ctx));
}

__attribute__((export_name("cabi_realloc"))) void *cabi_realloc(void *ptr,
                                                                size_t size) {
  return realloc(ptr, size);
}

__attribute__((export_name("cabi_free"))) void cabi_free(void *ptr) {
  free(ptr);
}

extern void ruby_c10zrt_invoke_import(void *func, VALUE *argv);

static VALUE rb_call_wasm_import(int argc, VALUE *argv, VALUE self) {
  // Exctract (module_name, name, *args) from argv
  if (argc < 2) {
    rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 2+)",
             argc);
  }
  VALUE module_name = argv[0];
  VALUE name = argv[1];
  VALUE *args = argv + 2;
  argc -= 2;

  if (TYPE(module_name) != T_STRING) {
    rb_raise(rb_eTypeError, "wrong argument type %s (expected String)",
             rb_obj_classname(module_name));
  }

  if (TYPE(name) != T_STRING) {
    rb_raise(rb_eTypeError, "wrong argument type %s (expected String)",
             rb_obj_classname(name));
  }

  const char *module_name_cstr = RSTRING_PTR(module_name);
  const char *name_cstr = RSTRING_PTR(name);

  import_func_entry *entry = find_import_func(module_name_cstr, name_cstr);
  if (entry == NULL) {
    rb_raise(rb_eRuntimeError, "import function %s.%s is not registered",
             module_name_cstr, name_cstr);
  }

  ruby_c10zrt_invoke_import(entry->func, args);
  return Qnil;
}

void Init_c10zrt() {
  rb_mWaddle = rb_define_module("Waddle");
  rb_define_module_function(rb_mWaddle, "call_wasm_import", rb_call_wasm_import,
                            -1);

  // 0 is reserved for import registration function
  ruby_c10zrt_invoke_import(0, 0);
}
