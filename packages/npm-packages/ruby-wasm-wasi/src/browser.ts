import { init, WASI } from "@wasmer/wasi";
import { RubyVM } from "./index.js";
import { consolePrinter } from "./console.js";

export const DefaultRubyVM = async (
  rubyModule: WebAssembly.Module,
  options: {
    consolePrint?: boolean;
    env?: Record<string, string> | undefined;
  } = {},
): Promise<{
  vm: RubyVM;
  wasi: WASI;
  instance: WebAssembly.Instance;
}> => {
  await init();

  const wasi = new WASI({ env: options.env });
  const vm = new RubyVM();

  const imports = wasi.getImports(rubyModule) as WebAssembly.Imports;
  vm.addToImports(imports);
  const printer = options.consolePrint ?? true ? consolePrinter() : undefined;
  printer?.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);
  wasi.instantiate(instance);
  await vm.setInstance(instance);

  printer?.setMemory(instance.exports.memory as WebAssembly.Memory);

  // Manually call `_initialize`, which is a part of reactor model ABI,
  // because the WASI polyfill doesn't support it yet.
  (instance.exports._initialize as Function)();
  vm.initialize();

  return {
    vm,
    wasi,
    instance,
  };
};
