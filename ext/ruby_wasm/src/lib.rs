use std::{collections::HashMap, path::PathBuf};

use magnus::{
    eval, exception, function, method,
    prelude::*,
    value::{self, InnerValue},
    wrap, Error, ExceptionClass, RModule, Ruby,
};
use structopt::StructOpt;
use wizer::Wizer;

static RUBY_WASM: value::Lazy<RModule> =
    value::Lazy::new(|ruby| ruby.define_module("RubyWasmExt").unwrap());

fn preinit(core_module: bytes::Bytes) -> Result<bytes::Bytes, Error> {
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
        .map(|output| output.into())
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
        self.0
            .borrow_mut()
            .map_dirs
            .push((guest_dir.into(), host_dir.into()));
    }

    fn pack(&self, wasm_bytes: bytes::Bytes) -> Result<bytes::Bytes, Error> {
        let output_bytes = wasi_vfs_cli::pack(&wasm_bytes, self.0.borrow().map_dirs.clone())
            .map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to pack wasi vfs: {}", e),
                )
            })?;
        Ok(output_bytes.into())
    }
}

#[wrap(class = "RubyWasmExt::ComponentLink")]
struct ComponentLink(std::cell::RefCell<Option<wit_component::Linker>>);

impl ComponentLink {
    fn new() -> Self {
        Self(std::cell::RefCell::new(Some(
            wit_component::Linker::default(),
        )))
    }
    fn linker(
        &self,
        body: impl FnOnce(wit_component::Linker) -> Result<wit_component::Linker, Error>,
    ) -> Result<(), Error> {
        let mut linker = self.0.take().ok_or_else(|| {
            Error::new(
                exception::standard_error(),
                "linker is already consumed".to_string(),
            )
        })?;
        linker = body(linker)?;
        self.0.replace(Some(linker));
        Ok(())
    }

    fn library(&self, name: String, module: bytes::Bytes, dl_openable: bool) -> Result<(), Error> {
        self.linker(|linker| {
            linker.library(&name, &module, dl_openable).map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to link library: {}", e),
                )
            })
        })
    }
    fn adapter(&self, name: String, module: bytes::Bytes) -> Result<(), Error> {
        self.linker(|linker| {
            linker.adapter(&name, &module).map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to link adapter: {}", e),
                )
            })
        })
    }
    fn validate(&self, validate: bool) -> Result<(), Error> {
        self.linker(|linker| Ok(linker.validate(validate)))
    }
    fn stack_size(&self, size: u32) -> Result<(), Error> {
        self.linker(|linker| Ok(linker.stack_size(size)))
    }
    fn stub_missing_functions(&self, stub: bool) -> Result<(), Error> {
        self.linker(|linker| Ok(linker.stub_missing_functions(stub)))
    }
    fn use_built_in_libdl(&self, use_libdl: bool) -> Result<(), Error> {
        self.linker(|linker| Ok(linker.use_built_in_libdl(use_libdl)))
    }
    fn encode(&self) -> Result<bytes::Bytes, Error> {
        // Take the linker out of the cell and consume it
        let linker = self.0.borrow_mut().take().ok_or_else(|| {
            Error::new(
                exception::standard_error(),
                "linker is already consumed".to_string(),
            )
        })?;
        let encoded = linker.encode().map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to encode linker: {}", e),
            )
        })?;
        Ok(encoded.into())
    }
}

#[wrap(class = "RubyWasmExt::ComponentEncode")]
struct ComponentEncode(std::cell::RefCell<Option<wit_component::ComponentEncoder>>);

impl ComponentEncode {
    fn new() -> Self {
        Self(std::cell::RefCell::new(Some(
            wit_component::ComponentEncoder::default(),
        )))
    }

    fn encoder(
        &self,
        body: impl FnOnce(
            wit_component::ComponentEncoder,
        ) -> Result<wit_component::ComponentEncoder, Error>,
    ) -> Result<(), Error> {
        let mut encoder = self.0.take().ok_or_else(|| {
            Error::new(
                exception::standard_error(),
                "encoder is already consumed".to_string(),
            )
        })?;
        encoder = body(encoder)?;
        self.0.replace(Some(encoder));
        Ok(())
    }

    fn validate(&self, validate: bool) -> Result<(), Error> {
        self.encoder(|encoder| Ok(encoder.validate(validate)))
    }

    fn adapter(&self, name: String, module: bytes::Bytes) -> Result<(), Error> {
        self.encoder(|encoder| {
            encoder.adapter(&name, &module).map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to encode adapter: {}", e),
                )
            })
        })
    }

    fn module(&self, module: bytes::Bytes) -> Result<(), Error> {
        self.encoder(|encoder| {
            encoder.module(&module).map_err(|e| {
                Error::new(
                    exception::standard_error(),
                    format!("failed to encode module: {}", e),
                )
            })
        })
    }

    fn realloc_via_memory_grow(&self, realloc: bool) -> Result<(), Error> {
        self.encoder(|encoder| Ok(encoder.realloc_via_memory_grow(realloc)))
    }

    fn import_name_map(&self, map: HashMap<String, String>) -> Result<(), Error> {
        self.encoder(|encoder| Ok(encoder.import_name_map(map)))
    }

    fn encode(&self) -> Result<bytes::Bytes, Error> {
        // Take the encoder out of the cell and consume it
        let encoder = self.0.borrow_mut().take().ok_or_else(|| {
            Error::new(
                exception::standard_error(),
                "encoder is already consumed".to_string(),
            )
        })?;
        let encoded = encoder.encode().map_err(|e| {
            Error::new(
                exception::standard_error(),
                format!("failed to encode component: {}", e),
            )
        })?;
        Ok(encoded.into())
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

    let component_link = module.define_class("ComponentLink", ruby.class_object())?;
    component_link.define_singleton_method("new", function!(ComponentLink::new, 0))?;
    component_link.define_method("library", method!(ComponentLink::library, 3))?;
    component_link.define_method("adapter", method!(ComponentLink::adapter, 2))?;
    component_link.define_method("validate", method!(ComponentLink::validate, 1))?;
    component_link.define_method("stack_size", method!(ComponentLink::stack_size, 1))?;
    component_link.define_method(
        "stub_missing_functions",
        method!(ComponentLink::stub_missing_functions, 1),
    )?;
    component_link.define_method(
        "use_built_in_libdl",
        method!(ComponentLink::use_built_in_libdl, 1),
    )?;
    component_link.define_method("encode", method!(ComponentLink::encode, 0))?;

    let component_encode = module.define_class("ComponentEncode", ruby.class_object())?;
    component_encode.define_singleton_method("new", function!(ComponentEncode::new, 0))?;
    component_encode.define_method("validate", method!(ComponentEncode::validate, 1))?;
    component_encode.define_method("adapter", method!(ComponentEncode::adapter, 2))?;
    component_encode.define_method("module", method!(ComponentEncode::module, 1))?;
    component_encode.define_method(
        "realloc_via_memory_grow",
        method!(ComponentEncode::realloc_via_memory_grow, 1),
    )?;
    component_encode.define_method(
        "import_name_map",
        method!(ComponentEncode::import_name_map, 1),
    )?;
    component_encode.define_method("encode", method!(ComponentEncode::encode, 0))?;

    Ok(())
}
