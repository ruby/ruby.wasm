import { Fd, WASI } from "@bjorn3/browser_wasi_shim";
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
  const args: string[] = [];
  const env: string[] = Object.entries(options.env ?? {}).map(
    ([k, v]) => `${k}=${v}`,
  );

  const fds: Fd[] = [];
  const wasi = new WASI(args, env, fds, { debug: false });
  const vm = new RubyVM();

  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);
  const printer = options.consolePrint ?? true ? consolePrinter() : undefined;
  printer?.addToImports(imports);

  {
    // WORKAROUND: browser_wasi_shim does not support some syscalls yet
    // and returns -1 instead of proper ERRNO values and it results in confusing
    // error messages "Success -- /path/to/file".
    // Update browser_wasi_shim version when my fix[^1] will be released.
    // [^1]: https://github.com/bjorn3/browser_wasi_shim/commit/6193f7482633ef818604375d9755ded67946adfc
    const syscalls = imports["wasi_snapshot_preview1"];
    for (const name of Object.keys(syscalls)) {
      const original = syscalls[name];
      syscalls[name] = (...args) => {
        const result = original(...args);
        if (result === -1) {
          return 58; // ENOTSUP
        }
        // browser_wasi_shim's `random_get` returns `undefined` on success
        // instead of `0`.
        if (result === undefined) {
          return 0; // Success
        }
        return result;
      };
    }
  }

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
