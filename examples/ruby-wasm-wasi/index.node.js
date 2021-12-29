import { WASI } from "wasi"
import fs from "fs/promises";

// $ node --experimental-wasi-unstable-preview1 index.node.js

const main = async () => {
  const args = ["ruby.wasm", "--disable-gems", "-e", "puts 'Hello :)'"];
  const wasi = new WASI({ args });
  console.log(`$ ${args.join(" ")}`)
  const binary = await fs.readFile("./node_modules/ruby-wasm-wasi/bin/ruby.wasm");
  const { instance } = await WebAssembly.instantiate(binary.buffer, {
    wasi_snapshot_preview1: wasi.wasiImport,
  });
  wasi.start(instance);
};

main()
