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
  const printer = options.consolePrint ?? true ? consolePrinter() : undefined;
  const { vm, instance } = await RubyVM.instantiateModule({
    module: rubyModule, wasip1: wasi,
    addToImports: (imports) => {
      printer?.addToImports(imports);
    },
    setMemory: (memory) => {
      printer?.setMemory(memory);
    }
  });

  return {
    vm,
    wasi,
    instance,
  };
};
