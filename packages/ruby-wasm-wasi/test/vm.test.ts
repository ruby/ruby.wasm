import { RubyVM } from "../dist/index";
import { WASI } from "wasi";
import * as fs from "fs/promises";
import * as path from "path";

const rubyModule = (async () => {
  const binary = await fs.readFile(
    path.join(__dirname, "./../dist/bin/ruby.wasm")
  );
  return await WebAssembly.compile(binary.buffer);
})();

const initRubyVM = async () => {
  const wasi = new WASI();
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(await rubyModule, imports);
  await vm.init(instance);
  wasi.initialize(instance);
  vm.guest.rubyInit();
  return vm;
};

describe("RubyVM", () => {
  test("empty expression", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("");
    expect(result.rawValue()).toBe(/* Qnil */ 4);
  });
  test("nil toString", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("nil");
    expect(result.toString()).toBe("");
  });
});
