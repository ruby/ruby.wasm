import fs from "fs/promises";
import path from "path";
import { WASI } from "wasi";
import { RubyVM } from "../dist/index.umd.js";
import { DefaultRubyVM } from "../src/node";

const initRubyVM = async (rubyModule: WebAssembly.Module, args: string[]) => {
  const wasi = new WASI();
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };

  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);

  await vm.setInstance(instance);

  wasi.initialize(instance);
  vm.initialize();

  return {
    vm,
    wasi,
    instance,
  };
};

describe("Packaging validation", () => {
  jest.setTimeout(20 /*sec*/ * 1000);

  const moduleCache = new Map<string, WebAssembly.Module>();
  const loadWasmModule = async (file: string) => {
    if (moduleCache.has(file)) {
      return moduleCache.get(file)!;
    }
    const binary = await fs.readFile(path.join(__dirname, `./../dist/${file}`));
    const mod = await WebAssembly.compile(binary.buffer);
    moduleCache.set(file, mod);
    return mod;
  };

  test("DefaultRubyVM", async () => {
    const mod = await loadWasmModule(`ruby+stdlib.wasm`);
    const { vm } = await DefaultRubyVM(mod);
    vm.eval(`require "stringio"`);
  });

  test.each([
    { file: "ruby+stdlib.wasm", stdlib: true },
    { file: "ruby.debug+stdlib.wasm", stdlib: true },
  ])("Load all variants", async ({ file, stdlib }) => {
    const mod = await loadWasmModule(file);
    const { vm } = await initRubyVM(mod, ["ruby.wasm", "-e_=0"]);
    // Check loading ext library
    vm.eval(`require "stringio"`);
    if (stdlib) {
      // Check loading stdlib gem
      vm.eval(`require "English"`);
    }
  });

  test("ruby.debug+stdlib.wasm has debug info", async () => {
    const mod = await loadWasmModule("ruby.debug+stdlib.wasm");
    const nameSections = WebAssembly.Module.customSections(mod, "name");
    expect(nameSections.length).toBe(1);
  });
});
