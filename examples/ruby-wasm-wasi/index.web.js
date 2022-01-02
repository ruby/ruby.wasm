import { WASI } from "./node_modules/@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import { RubyVM } from "ruby-wasm-wasi";

const main = async () => {
  // Setup WASI emulation
  const wasmFs = new WasmFs();
  const originalWriteSync = wasmFs.fs.writeSync;
  wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
    const text = new TextDecoder("utf-8").decode(buffer);
    switch (fd) {
      case 1:
        console.log(text);
        break;
      case 2:
        console.warn(text);
        break;
    }
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
  await vm.init(instance);
  // Start WASI application
  wasi.setMemory(instance.exports.memory);
  vm.guest.rubyInit();
  const ret = vm.guest.rbEvalStringProtect("p 1\0");
  console.log(ret);
};

main();
