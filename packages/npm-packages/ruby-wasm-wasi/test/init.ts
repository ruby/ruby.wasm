import { WASI } from "wasi";
import fs from "fs/promises";
import path from "path";
import { RubyVM } from "../dist/index.umd.js";

const rubyModule = (async () => {
  const binary = await fs.readFile(path.join(__dirname, "./../dist/ruby.wasm"));
  return await WebAssembly.compile(binary.buffer);
})();

export const initRubyVM = async () => {
  const wasi = new WASI();
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(await rubyModule, imports);
  await vm.setInstance(instance);
  wasi.initialize(instance);
  vm.initialize();
  return vm;
};
