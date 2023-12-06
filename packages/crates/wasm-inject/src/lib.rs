use std::collections::HashMap;

use anyhow::{anyhow, Ok, Result};
use walrus::{ir::Value, ModuleConfig, ValType};

pub use walrus;

struct InjectedImportFunc {
    name: String,
    trampoline: walrus::FunctionId,
}
pub struct WasmInject {
    prefix: String,
    module: walrus::Module,
    injected_imports: HashMap<String, Vec<InjectedImportFunc>>,
    imports_table: walrus::TableId,
}

mod abi {
    // Canonical ABI
    pub(crate) const CABI_REALLOC: &str = "cabi_realloc";
    pub(crate) const CABI_FREE: &str = "cabi_free";

    // wasm-inject ABI
    // fn push_{T}(val: T, ctx: ptr) -> ()
    pub(crate) const PUSH_I32: &str = "push_i32";
    pub(crate) const PUSH_I64: &str = "push_i64";
    pub(crate) const PUSH_F32: &str = "push_f32";
    pub(crate) const PUSH_F64: &str = "push_f64";
    // fn pop_{T}(ctx: ptr) -> T
    pub(crate) const POP_I32: &str = "pop_i32";
    pub(crate) const POP_I64: &str = "pop_i64";
    pub(crate) const POP_F32: &str = "pop_f32";
    pub(crate) const POP_F64: &str = "pop_f64";
    // fn call_export_func(name: *const u8, ctx: ptr) -> ()
    pub(crate) const CALL_EXPORT_FUNC: &str = "call_export_func";
    // fn add_import_func(module_name: *const u8, name: *const u8, func: ptr) -> ()
    pub(crate) const ADD_IMPORT_FUNC: &str = "add_import_func";
    // fn init_context() -> ptr
    pub(crate) const INIT_CONTEXT: &str = "init_context";
    // fn destroy_context(ctx: ptr) -> ()
    pub(crate) const DESTROY_CONTEXT: &str = "destroy_context";
}

impl WasmInject {
    pub fn new(core_module: &[u8], prefix: &str) -> Result<Self> {
        let mut module_config = ModuleConfig::new();
        module_config.generate_name_section(true);
        let module = module_config.parse(core_module)?;
        let export_name = format!("{}.imports_table", prefix);
        let imports_table = Self::imports_table(&module, &export_name)?;
        Ok(Self {
            prefix: prefix.to_string(),
            module,
            injected_imports: HashMap::new(),
            imports_table,
        })
    }

    fn get_export_func(&self, name: &str) -> Result<walrus::FunctionId> {
        self.module
            .exports
            .get_func(format!("{}.{}", self.prefix, name))
    }

    pub fn add_export_func(
        &mut self,
        name: &str,
        params: &[ValType],
        results: &[ValType],
    ) -> Result<()> {
        let mut func = walrus::FunctionBuilder::new(&mut self.module.types, params, results);
        func.name(name.to_string());
        let mut body = func.func_body();

        let memory = Self::get_memory(&self.module)?;

        let name_ptr = self.module.locals.add(ValType::I32);
        let name_bytes = [name.as_bytes(), b"\0"].concat();

        let cabi_realloc = self.get_cabi_func(abi::CABI_REALLOC)?;

        body.i32_const(0)
            .i32_const(name_bytes.len() as i32)
            .call(cabi_realloc)
            .local_set(name_ptr);

        // 1. Allocate a string for the name
        store_string_at(&mut body, memory, &name_bytes, name_ptr, 0);

        let call_export_func = self.get_export_func(abi::CALL_EXPORT_FUNC)?;
        let init_ctx = self.get_export_func(abi::INIT_CONTEXT)?;

        let ctx = self.module.locals.add(ValType::I32);

        // 2. Allocate a stack context
        body.call(init_ctx).local_set(ctx);

        // 3. Push parameters to the stack
        let args = params.iter().map(|p| {
            self.module.locals.add(*p)
        }).collect::<Vec<_>>();
        for (idx, param) in params.iter().enumerate().rev() {
            let local = args[idx];
            match param {
                ValType::I32 => body.local_get(local).local_get(ctx).call(self.get_export_func(abi::PUSH_I32)?),
                ValType::I64 => body.local_get(local).local_get(ctx).call(self.get_export_func(abi::PUSH_I64)?),
                ValType::F32 => body.local_get(local).local_get(ctx).call(self.get_export_func(abi::PUSH_F32)?),
                ValType::F64 => body.local_get(local).local_get(ctx).call(self.get_export_func(abi::PUSH_F64)?),
                _ => unimplemented!("unsupported param type: {:?}", param),
            };
        }

        // 4. Call the exposed function by function name
        body.local_get(ctx)
            .local_get(name_ptr)
            .call(call_export_func);

        // 5. Deallocate the function name
        body.local_get(name_ptr).call(self.get_cabi_func(abi::CABI_FREE)?);

        // 6. Pop results from the stack
        for result in results.iter() {
            match result {
                ValType::I32 => body.local_get(ctx).call(self.get_export_func(abi::POP_I32)?),
                ValType::I64 => body.local_get(ctx).call(self.get_export_func(abi::POP_I64)?),
                ValType::F32 => body.local_get(ctx).call(self.get_export_func(abi::POP_F32)?),
                ValType::F64 => body.local_get(ctx).call(self.get_export_func(abi::POP_F64)?),
                _ => unimplemented!("unsupported result type: {:?}", result),
            };
        }

        // 7. Deallocate the stack context
        body.local_get(ctx).call(self.get_export_func(abi::DESTROY_CONTEXT)?);

        body.return_();

        let func = func.finish(args, &mut self.module.funcs);
        self.module.exports.add(name, func);

        Ok(())
    }

    pub fn add_import_func(
        &mut self,
        module: &str,
        name: &str,
        params: &[ValType],
        results: &[ValType],
    ) -> Result<()> {
        let ty = self
            .module
            .types
            .find(params, results)
            .unwrap_or_else(|| self.module.types.add(params, results));
        self.add_import_func_with_tyid(module, name, ty)
    }

    fn add_import_func_with_tyid(
        &mut self,
        module: &str,
        name: &str,
        ty: walrus::TypeId,
    ) -> Result<()> {
        let (import_func, _) = self.module.add_import_func(module, name, ty);
        let ty = self.module.types.get(ty);
        let params = ty.params().to_vec();
        let results = ty.results().to_vec();

        let ctx_ty = ValType::I32;
        let mut builder = walrus::FunctionBuilder::new(&mut self.module.types, &[ctx_ty], &[]);
        let ctx = self.module.locals.add(ctx_ty);
        let mut body = builder.func_body();

        // 1. Pop parameters from the stack
        for param in params.iter() {
            match param {
                ValType::I32 => body.local_get(ctx).call(self.get_export_func(abi::POP_I32)?),
                ValType::I64 => body.local_get(ctx).call(self.get_export_func(abi::POP_I64)?),
                ValType::F32 => body.local_get(ctx).call(self.get_export_func(abi::POP_F32)?),
                ValType::F64 => body.local_get(ctx).call(self.get_export_func(abi::POP_F64)?),
                _ => unimplemented!("unsupported param type: {:?}", param),
            };
        }

        // 2. Call the import function
        body.call(import_func);

        // 3. Push results to the stack
        for result in results.iter().rev() {
            match result {
                ValType::I32 => body.local_get(ctx).call(self.get_export_func(abi::PUSH_I32)?),
                ValType::I64 => body.local_get(ctx).call(self.get_export_func(abi::PUSH_I64)?),
                ValType::F32 => body.local_get(ctx).call(self.get_export_func(abi::PUSH_F32)?),
                ValType::F64 => body.local_get(ctx).call(self.get_export_func(abi::PUSH_F64)?),
                _ => unimplemented!("unsupported result type: {:?}", result),
            };
        }

        let func = builder.finish(vec![ctx], &mut self.module.funcs);
        self.injected_imports
            .entry(module.to_string())
            .or_default()
            .push(InjectedImportFunc {
                name: name.to_string(),
                trampoline: func,
            });
        Ok(())
    }

    pub fn run(&mut self) -> Result<Vec<u8>> {
        // 1. Create a new registrar function
        let registrar = self.make_import_registrar()?;
        // 2. Create a new Element segment with the import trampolines
        let mut members = vec![Some(registrar)];
        for (_, entries) in self.injected_imports.iter() {
            for entry in entries {
                members.push(Some(entry.trampoline));
            }
        }
        let members_len = members.len();

        self.module.elements.add(
            walrus::ElementKind::Active {
                table: self.imports_table,
                offset: walrus::InitExpr::Value(Value::I32(0)),
            },
            ValType::Funcref,
            members,
        );
        self.module.tables.get_mut(self.imports_table).initial = members_len as u32;
        Ok(self.module.emit_wasm())
    }

    fn make_import_registrar(&mut self) -> Result<walrus::FunctionId> {
        let params = [ValType::I32]; // unused context to be called by ruby_c10zrt_invoke_import
        let mut builder = walrus::FunctionBuilder::new(&mut self.module.types, &params, &[]);
        builder.name(format!("{}.init_add_import_func", self.prefix));
        let mut body = builder.func_body();

        let cabi_realloc = self.get_cabi_func(abi::CABI_REALLOC)?;
        let add_import_func = self.get_export_func(abi::ADD_IMPORT_FUNC)?;
        let memory = Self::get_memory(&self.module)?;
        let module_name_ptr = self.module.locals.add(ValType::I32);
        let name_ptr = self.module.locals.add(ValType::I32);

        let mut element_index = 1; // 0 is preserved for this registrar function

        for (module_name, entries) in self.injected_imports.iter() {
            let module_name = [module_name.as_bytes(), b"\0"].concat();
            body.i32_const(0)
                .i32_const(module_name.len() as i32)
                .call(cabi_realloc)
                .local_set(module_name_ptr);
            store_string_at(&mut body, memory, &module_name, module_name_ptr, 0);

            for entry in entries {
                let name = [entry.name.as_bytes(), b"\0"].concat();
                // Allocate a string for the name
                body.i32_const(0)
                    .i32_const(name.len() as i32)
                    .call(cabi_realloc)
                    .local_set(name_ptr);
                store_string_at(&mut body, memory, &name, name_ptr, 0);

                // Register the import
                body.local_get(module_name_ptr)
                    .local_get(name_ptr)
                    .i32_const(element_index)
                    .call(add_import_func);

                element_index += 1;
            }
        }
        // No need to free the strings, since the buffer ownership is transferred to the application

        Ok(builder.finish(vec![], &mut self.module.funcs))
    }

    fn imports_table(module: &walrus::Module, export_name: &str) -> Result<walrus::TableId> {
        for export in module.exports.iter() {
            if export.name == export_name {
                return match export.item {
                    walrus::ExportItem::Table(id) => Ok(id),
                    _ => return Err(anyhow!("export named {} is not a table", export_name)),
                };
            }
        }
        Err(anyhow!("no export named {} found", export_name))
    }

    fn get_memory(module: &walrus::Module) -> Result<walrus::MemoryId> {
        for export in module.exports.iter() {
            if export.name == "memory" {
                return match export.item {
                    walrus::ExportItem::Memory(id) => Ok(id),
                    _ => return Err(anyhow!("export named memory is not a memory")),
                };
            }
        }
        Err(anyhow!("no export named memory found"))
    }

    fn get_cabi_func(&self, name: &str) -> Result<walrus::FunctionId> {
        self.module.exports.get_func(name)
    }
}

fn usize_to_wasm_i32(x: usize) -> Value {
    Value::I32(i32::from_le_bytes((x as u32).to_le_bytes()))
}

fn store_string_at(
    builder: &mut walrus::InstrSeqBuilder,
    memory: walrus::MemoryId,
    bytes: &[u8],
    base: walrus::LocalId,
    offset: usize,
) {
    let mut written = 0;
    for chunk_size in [8, 4, 2, 1] {
        let chunk_count = (bytes.len() - written) / chunk_size;
        for _ in 0..chunk_count {
            use walrus::ir::{BinaryOp, MemArg, StoreKind};

            let chunk = &bytes[written..written + chunk_size];
            let (v, kind) = match chunk_size {
                8 => (
                    Value::I64(i64::from_le_bytes(chunk.try_into().unwrap())),
                    StoreKind::I64 { atomic: false },
                ),
                4 => (
                    Value::I32(i32::from_le_bytes(chunk.try_into().unwrap())),
                    StoreKind::I32 { atomic: false },
                ),
                2 => (
                    Value::I32(i16::from_le_bytes(chunk.try_into().unwrap()) as i32),
                    StoreKind::I32_16 { atomic: false },
                ),
                1 => (
                    Value::I32(i8::from_le_bytes(chunk.try_into().unwrap()) as i32),
                    StoreKind::I32_8 { atomic: false },
                ),
                _ => unreachable!(),
            };
            builder
                .local_get(base)
                .const_(usize_to_wasm_i32(offset + written))
                .binop(BinaryOp::I32Add)
                .const_(v)
                .store(
                    memory,
                    kind,
                    MemArg {
                        align: 1,
                        offset: 0,
                    },
                );
            written += chunk_size;
        }
    }
}
