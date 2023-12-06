mod types;

use std::path::PathBuf;

use magnus::{
    eval, exception, function, method,
    prelude::*,
    value::{self, InnerValue},
    wrap, Error, ExceptionClass, RArray, RModule, Ruby,
};
use types::ValType;
use wizer::Wizer;

static RUBY_WASM: value::Lazy<RModule> =
    value::Lazy::new(|ruby| ruby.define_module("RubyWasmExt").unwrap());

fn preinit(core_module: Vec<u8>) -> Result<Vec<u8>, Error> {
    let rbwasm_error = eval("RubyWasmExt::Error")?;
    let rbwasm_error = ExceptionClass::from_value(rbwasm_error).unwrap();
    let mut wizer = Wizer::new();
    wizer
        .wasm_bulk_memory(true)
        .inherit_stdio(true)
        .inherit_env(true)
        .allow_wasi(true)
        .map_err(|e| Error::new(rbwasm_error, format!("failed to create wizer: {}", e)))?;

    wizer
        .run(&core_module)
        .map_err(|e| Error::new(rbwasm_error, format!("failed to run wizer: {}", e)))
}

#[wrap(class = "RubyWasmExt::WasmInject")]
struct WasmInject(std::cell::RefCell<wasm_inject::WasmInject>);

impl WasmInject {
    fn new(core_module: Vec<u8>) -> Result<Self, Error> {
        let inner = wasm_inject::WasmInject::new(&core_module, "ruby.c10zrt").map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to create componentizer: {}", e),
            )
        })?;
        Ok(Self(std::cell::RefCell::new(inner)))
    }

    fn add_export_func(&self, name: String, params: RArray, results: RArray) -> Result<(), Error> {
        let params = ValType::vec_from_rarray(params)?;
        let results = ValType::vec_from_rarray(results)?;
        self.0
            .borrow_mut()
            .add_export_func(&name, &params, &results)
            .map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to add export func: {}", e),
                )
            })?;
        Ok(())
    }

    fn add_import_func(
        &self,
        module: String,
        name: String,
        params: RArray,
        results: RArray,
    ) -> Result<(), Error> {
        let params = ValType::vec_from_rarray(params)?;
        let results = ValType::vec_from_rarray(results)?;
        self.0
            .borrow_mut()
            .add_import_func(&module, &name, &params, &results)
            .map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to add import func: {}", e),
                )
            })?;
        Ok(())
    }

    fn run(&self) -> Result<Vec<u8>, Error> {
        let wasm = self.0.borrow_mut().run().map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to run componentizer: {}", e),
            )
        })?;
        Ok(wasm)
    }
}

struct WasiVfsInner {
    map_dirs: Vec<(PathBuf, PathBuf)>,
}

#[wrap(class = "RubyWasmExt::WasiVfs")]
struct WasiVfs(std::cell::RefCell<WasiVfsInner>);

impl WasiVfs {
    fn new() -> Self {
        Self(std::cell::RefCell::new(WasiVfsInner { map_dirs: vec![] }))
    }

    fn map_dir(&self, guest_dir: String, host_dir: String) {
        self.0.borrow_mut().map_dirs.push((guest_dir.into(), host_dir.into()));
    }

    fn pack(&self, wasm_bytes: Vec<u8>) -> Result<Vec<u8>, Error> {
        let output_bytes = wasi_vfs_cli::pack(&wasm_bytes, self.0.borrow().map_dirs.clone()).map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to pack wasi vfs: {}", e),
            )
        })?;
        Ok(output_bytes)
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = RUBY_WASM.get_inner_with(ruby);
    module.define_error("Error", exception::standard_error())?;

    module.define_singleton_method("preinitialize", function!(preinit, 1))?;

    let wasm_inject = module.define_class("WasmInject", ruby.class_object())?;
    wasm_inject.define_singleton_method("new", function!(WasmInject::new, 1))?;
    wasm_inject.define_method("add_export_func", method!(WasmInject::add_export_func, 3))?;
    wasm_inject.define_method("add_import_func", method!(WasmInject::add_import_func, 4))?;
    wasm_inject.define_method("run", method!(WasmInject::run, 0))?;

    let wasi_vfs = module.define_class("WasiVfs", ruby.class_object())?;
    wasi_vfs.define_singleton_method("new", function!(WasiVfs::new, 0))?;
    wasi_vfs.define_method("map_dir", method!(WasiVfs::map_dir, 2))?;
    wasi_vfs.define_method("pack", method!(WasiVfs::pack, 1))?;

    let val_type = module.define_class("ValType", ruby.class_object())?;
    val_type.define_singleton_method("new", function!(ValType::new, 1))?;
    Ok(())
}
