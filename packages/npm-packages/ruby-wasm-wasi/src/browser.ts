import { Fd, File, OpenFile, PreopenDirectory, WASI } from "@bjorn3/browser_wasi_shim";
import { consolePrinter } from "./console.js";
import { RubyVM } from "./vm.js";

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
  const args: string[] = [];
  const env: string[] = Object.entries(options.env ?? {}).map(
    ([k, v]) => `${k}=${v}`,
  );

  const fds: Fd[] = [
    new OpenFile(new File([])),
    new OpenFile(new File([])),
    new OpenFile(new File([])),
    new PreopenDirectory("/", new Map()),
  ];
  const wasi = new WASI(args, env, fds, { debug: false });
  const vm = new RubyVM();

  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);
  const printer = options.consolePrint ?? true ? consolePrinter() : undefined;
  printer?.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);
  await vm.setInstance(instance);

  printer?.setMemory(instance.exports.memory as WebAssembly.Memory);

  wasi.initialize(instance as any);
  vm.initialize();

  return {
    vm,
    wasi,
    instance,
  };
};
