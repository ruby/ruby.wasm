use walrus::{ExportItem, FunctionBuilder, Module, ModuleConfig, ValType};
use wasm_inject::WasmInject;

fn build_runtime_stub(m: &mut Module, prefix: &str) {
    let imports_table = m.tables.add_local(0, None, ValType::Funcref);
    m.exports.add(
        format!("{}.imports_table", prefix).as_str(),
        ExportItem::Table(imports_table),
    );
    let memory = m.memories.add_local(false, 1, None);
    m.exports.add("memory", ExportItem::Memory(memory));

    fn export(module: &mut Module, name: impl AsRef<str>, params: &[ValType], results: &[ValType]) {
        let mut builder = FunctionBuilder::new(&mut module.types, params, results);
        builder.name(name.as_ref().to_string());
        builder.func_body().unreachable();
        let func = builder.finish(vec![], &mut module.funcs);

        module
            .exports
            .add(name.as_ref(), ExportItem::Function(func));
    }

    {
        use ValType::*;
        let pfx = prefix;

        export(m, format!("{pfx}.call_export_func"), &[I32, I32], &[]);
        export(m, format!("{pfx}.add_import_func"), &[I32, I32, I32], &[]);
        export(m, format!("{pfx}.init_context"), &[], &[I32]);
        export(m, format!("{pfx}.destroy_context"), &[I32], &[]);
        export(m, format!("{pfx}.push_i32"), &[I32, I32], &[]);
        export(m, format!("{pfx}.push_i64"), &[I64, I32], &[]);
        export(m, format!("{pfx}.push_f32"), &[F32, I32], &[]);
        export(m, format!("{pfx}.push_f64"), &[F64, I32], &[]);
        export(m, format!("{pfx}.pop_i32"), &[I32], &[I32]);
        export(m, format!("{pfx}.pop_i64"), &[I32], &[I64]);
        export(m, format!("{pfx}.pop_f32"), &[I32], &[F32]);
        export(m, format!("{pfx}.pop_f64"), &[I32], &[F64]);
        export(m, "cabi_realloc", &[I32, I32], &[I32]);
        export(m, "cabi_free", &[I32], &[]);
    }
}

fn snapshot(name: &str, wasm_bytes: &[u8]) {
    use std::fs::File;
    use std::io::Write;

    let path = format!("tests/snapshots/{name}.wat");
    let contents = wasmprinter::print_bytes(wasm_bytes).unwrap();

    // Update snapshots if `UPDATE_SNAPSHOTS` env var is set or if the snapshot file doesn't exist
    let update_snapshots =
        std::env::var("UPDATE_SNAPSHOTS").is_ok() || !std::path::Path::new(&path).exists();

    if update_snapshots {
        let mut file = File::create(path).unwrap();
        file.write_all(contents.as_bytes()).unwrap();
    } else {
        let existing = std::fs::read(path).unwrap_or_default();
        let existing = String::from_utf8_lossy(&existing);
        assert_eq!(existing, contents);
    }
}

fn with_snapshot<F: FnOnce(&mut WasmInject) -> anyhow::Result<()>>(name: &str, f: F) {
    let mut module = Module::with_config(ModuleConfig::new());
    build_runtime_stub(&mut module, "my-mod");

    let mut inject = WasmInject::new(&module.emit_wasm(), "my-mod").unwrap();
    f(&mut inject).unwrap();
    let btyes = inject.run().expect("failed to run componentizer");

    snapshot(name, &btyes);
    wasmparser::validate(&btyes).expect("failed to validate wasm");
}

#[test]
fn import() {
    with_snapshot("import", |inject| {
        inject.add_import_func("t", "empty", &[], &[])?;
        inject.add_import_func("t", "p_i32", &[ValType::I32], &[])?;

        inject.add_import_func("t", "p_i32_i64", &[ValType::I32, ValType::I64], &[])?;

        inject.add_import_func("t", "r_i32", &[], &[ValType::I32])?;
        inject.add_import_func("t", "r_i32_i64", &[], &[ValType::I32, ValType::I64])?;

        inject.add_import_func(
            "t",
            "p_i32_i64_r_f32_f64",
            &[ValType::I32, ValType::I64],
            &[ValType::F32, ValType::F64],
        )?;
        Ok(())
    });
}

#[test]
fn export() {
    with_snapshot("export", |inject| {
        inject.add_export_func("empty", &[], &[])?;
        inject.add_export_func("p_i32", &[ValType::I32], &[])?;
        inject.add_export_func("p_i32_i64", &[ValType::I32, ValType::I64], &[])?;

        inject.add_export_func("r_i32", &[], &[ValType::I32])?;
        inject.add_export_func("r_i32_i64", &[], &[ValType::I32, ValType::I64])?;

        inject.add_export_func(
            "p_i32_i64_r_f32_f64",
            &[ValType::I32, ValType::I64],
            &[ValType::F32, ValType::F64],
        )?;
        Ok(())
    });
}
