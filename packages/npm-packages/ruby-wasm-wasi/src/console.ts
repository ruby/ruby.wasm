/**
 * Create a console printer that can be used as an overlay of WASI imports.
 * See the example below for how to use it.
 *
 * ```javascript
 * const imports = {
 *  "wasi_snapshot_preview1": wasi.wasiImport,
 * }
 * const printer = consolePrinter();
 * printer.addToImports(imports);
 *
 * const instance = await WebAssembly.instantiate(module, imports);
 * printer.setMemory(instance.exports.memory);
 * ```
 *
 * Note that the `stdout` and `stderr` functions are called with text, not
 * bytes. This means that bytes written to stdout/stderr will be decoded as
 * UTF-8 and then passed to the `stdout`/`stderr` functions every time a write
 * occurs without buffering.
 *
 * @param stdout A function that will be called when stdout is written to.
 *               Defaults to `console.log`.
 * @param stderr A function that will be called when stderr is written to.
 *               Defaults to `console.warn`.
 * @returns An object that can be used as an overlay of WASI imports.
 */
export function consolePrinter(
  {
    stdout,
    stderr,
  }: {
    stdout: (str: string) => void;
    stderr: (str: string) => void;
  } = {
    stdout: console.log,
    stderr: console.warn,
  },
) {
  let memory: WebAssembly.Memory | undefined = undefined;
  let view: DataView | undefined = undefined;

  const decoder = new TextDecoder();

  return {
    addToImports(imports: WebAssembly.Imports): void {
      const original = imports.wasi_snapshot_preview1.fd_write as (
        fd: number,
        iovs: number,
        iovsLen: number,
        nwritten: number,
      ) => number;
      imports.wasi_snapshot_preview1.fd_write = (
        fd: number,
        iovs: number,
        iovsLen: number,
        nwritten: number,
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

        const log = fd === 1 ? stdout : stderr;
        log(str);

        return 0;
      };
    },
    setMemory(m: WebAssembly.Memory) {
      memory = m;
      view = new DataView(m.buffer);
    },
  };
}
