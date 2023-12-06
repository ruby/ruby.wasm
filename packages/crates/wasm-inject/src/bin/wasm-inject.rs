fn main() {
    // Parse CLI args
    // ```
    // wasm-inject <file> <output>
    // ```

    let args: Vec<String> = std::env::args().collect();
    let file = args.get(1).expect("missing file");
    let output = args.get(2).expect("missing output");
    componentize(file, output);
}

fn componentize(file: &str, output: &str) {
    let core_module =
        std::fs::read(file).unwrap_or_else(|_| panic!("failed to read file: {}", file));
    let mut c10zer = wasm_inject::WasmInject::new(&core_module, "ruby.c10zrt")
        .expect("failed to create componentizer");

    c10zer
        .add_import_func("my_module", "hello", &[], &[])
        .expect("failed to add import func");
    c10zer
        .add_export_func("greet", &[], &[])
        .expect("failed to add export func");

    let wasm = c10zer.run().expect("failed to run componentizer");

    std::fs::write(output, wasm).expect("failed to write output");
}
