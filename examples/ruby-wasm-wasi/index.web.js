import { WASI } from "./node_modules/@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";

const main = async () => {
  // Setup WASI emulation
  const args = ["ruby.wasm", "--disable-gems", "-e", "puts 'Hello :)'"];
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
    args,
    bindings: {
      ...WASI.defaultBindings,
      fs: wasmFs.fs,
    },
  });
  // Fetch and instntiate WebAssembly binary
  const response = await fetch("./node_modules/ruby-wasm-wasi/bin/ruby.wasm");
  const buffer = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(buffer, {
    wasi_snapshot_preview1: wasi.wasiImport,
  });
  // Start WASI application
  console.log(`$ ${args.join(" ")}`)
  wasi.start(instance);
};

main();
