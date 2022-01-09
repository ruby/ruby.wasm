import { WASI } from "wasi";
import * as fs from "fs/promises";
import * as path from "path";
import { RubyVM } from "../dist/index";

const rubyModule = (async () => {
  const binary = await fs.readFile(
    path.join(__dirname, "./../dist/bin/ruby.wasm")
  );
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
  vm.guest.rubyInit();
  const args = ["ruby.wasm\0", "--disable-gems", "-e\0", "_=0\0"];
  vm.guest.rubySysinit(args);
  vm.guest.rubyOptions(args);
  return vm;
};
