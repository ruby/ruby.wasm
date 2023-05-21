import { WASI } from "wasi";
import { RubyVM } from "./index";

export const DefaultRubyVM = async (rubyModule: WebAssembly.Module) => {
  const wasi = new WASI({
    env: {
      // FIXME(katei): setjmp consumes a LOT of stack now, so we extend
      // default Fiber stack size as well as main stack size allocated
      // by wasm-ld's --stack-size. The ideal solution is to reduce
      // stack consumption in setjmp.
      "RUBY_FIBER_MACHINE_STACK_SIZE": "16777216"
    }
  });
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
