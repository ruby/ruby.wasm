use std::path::PathBuf;

use magnus::{
    eval, exception, function, method,
    prelude::*,
    value::{self, InnerValue},
    wrap, Error, ExceptionClass, RModule, Ruby,
};
use wizer::Wizer;
use structopt::StructOpt;

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

struct WasiVfsInner {
    map_dirs: Vec<(PathBuf, PathBuf)>,
}

#[wrap(class = "RubyWasmExt::WasiVfs")]
struct WasiVfs(std::cell::RefCell<WasiVfsInner>);

impl WasiVfs {
    fn run_cli(args: Vec<String>) -> Result<(), Error> {
        wasi_vfs_cli::App::from_iter(args).execute().map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to run wasi vfs cli: {}", e),
            )
        })
    }

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

    let wasi_vfs = module.define_class("WasiVfs", ruby.class_object())?;
    wasi_vfs.define_singleton_method("new", function!(WasiVfs::new, 0))?;
    wasi_vfs.define_singleton_method("run_cli", function!(WasiVfs::run_cli, 1))?;
    wasi_vfs.define_method("map_dir", method!(WasiVfs::map_dir, 2))?;
    wasi_vfs.define_method("pack", method!(WasiVfs::pack, 1))?;
    Ok(())
}
