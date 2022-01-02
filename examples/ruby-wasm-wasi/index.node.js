import { WASI } from "wasi"
import fs from "fs/promises";
import { RubyVM } from "ruby-wasm-wasi";

// $ node --experimental-wasi-unstable-preview1 index.node.js

const main = async () => {
  const wasi = new WASI();
  const binary = await fs.readFile("./node_modules/ruby-wasm-wasi/bin/ruby.wasm");
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const { instance } = await WebAssembly.instantiate(binary.buffer, imports);
  await vm.init(instance);
  // Start WASI application
  wasi.initialize(instance);
  vm.guest.rubyShowVersion();
  vm.guest.rubyInit();
  vm.guest.rbEvalStringProtect("puts 'Hey!'\0");
  vm.guest.rbEvalStringProtect("puts 'Hey!'\0");
  vm.guest.rbEvalStringProtect("puts 'Hey!'\0");
};

main()
