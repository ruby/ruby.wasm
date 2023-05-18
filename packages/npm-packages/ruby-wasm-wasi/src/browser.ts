import { init, WASI } from "@wasmer/wasi";
import { RubyVM } from "./index";

const consolePrinter = () => {
  let memory: WebAssembly.Memory | undefined = undefined;
  let view: DataView | undefined = undefined;

  const decoder = new TextDecoder();

  return {
    addToImports(imports: WebAssembly.Imports): void {
      const original = imports.wasi_snapshot_preview1.fd_write as (
        fd: number,
        iovs: number,
        iovsLen: number,
        nwritten: number
      ) => number;
      imports.wasi_snapshot_preview1.fd_write = (
        fd: number,
        iovs: number,
        iovsLen: number,
        nwritten: number
      ): number => {
        if (fd !== 1 && fd !== 2) {
          return original(fd, iovs, iovsLen, nwritten);
        }

        if (typeof memory === "undefined" || typeof view === "undefined") {
          throw new Error("Memory is not set");
        }
        if (view.buffer.byteLength === 0) {
          view = new DataView(memory.buffer);
        }

        const buffers = Array.from({ length: iovsLen }, (_, i) => {
          const ptr = iovs + i * 8;
          const buf = view.getUint32(ptr, true);
          const bufLen = view.getUint32(ptr + 4, true);
          return new Uint8Array(memory.buffer, buf, bufLen);
        });

        let written = 0;
        let str = "";
        for (const buffer of buffers) {
          str += decoder.decode(buffer);
          written += buffer.byteLength;
        }
        view.setUint32(nwritten, written, true);

        const log = fd === 1 ? console.log : console.warn;
        log(str);

        return 0;
      };
    },
    setMemory(m: WebAssembly.Memory) {
      memory = m;
      view = new DataView(m.buffer);
    },
  };
};

export const DefaultRubyVM = async (
  rubyModule: WebAssembly.Module,
  options: { consolePrint: boolean } = { consolePrint: true }
): Promise<{
  vm: RubyVM;
  wasi: WASI;
  instance: WebAssembly.Instance;
}> => {
  await init();

  const wasi = new WASI({});
  const vm = new RubyVM();

  const imports = wasi.getImports(rubyModule) as WebAssembly.Imports;
  vm.addToImports(imports);
  const printer = options.consolePrint ? consolePrinter() : undefined;
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
