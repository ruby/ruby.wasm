import { WASI } from "./node_modules/@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import { RubyVM } from "ruby-wasm-wasi";

const main = async () => {
  // Setup WASI emulation
  const wasmFs = new WasmFs();
  const originalWriteSync = wasmFs.fs.writeSync.bind(wasmFs.fs);
  wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
    const text = new TextDecoder("utf-8").decode(buffer);
    const handlers = {
      1: (line) => console.log(line),
      2: (line) => console.warn(line),
    };
    if (handlers[fd]) handlers[fd](text);
    return originalWriteSync(fd, buffer, offset, length, position);
  };
  const wasi = new WASI({
    bindings: {
      ...WASI.defaultBindings,
      fs: wasmFs.fs,
    },
  });
  // Fetch and instntiate WebAssembly binary
  const response = await fetch("./node_modules/ruby-wasm-wasi/bin/ruby.wasm");
  const buffer = await response.arrayBuffer();
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const { instance } = await WebAssembly.instantiate(buffer, imports);
  await vm.setInstance(instance);
  // Start WASI application
  wasi.setMemory(instance.exports.memory);
  vm.initialize();

  vm.printVersion();

  runRubyScriptsInHtml(vm);
};

const runRubyScriptsInHtml = (vm) => {
  const tags = document.getElementsByTagName("script");
  for (var i = 0, len = tags.length; i < len; i++) {
    const tag = tags[i];
    if (tag.type === "text/ruby") {
      if (tag.innerHTML) {
        vm.eval(tag.innerHTML);
      }
    }
  }
};

main();
