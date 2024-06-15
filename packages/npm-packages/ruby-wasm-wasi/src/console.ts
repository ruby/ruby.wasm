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
  let _view: DataView | undefined = undefined;

  function getMemoryView(): DataView {
    if (typeof memory === "undefined") {
      throw new Error("Memory is not set");
    }
    if (_view === undefined || _view.buffer.byteLength === 0) {
      _view = new DataView(memory.buffer);
    }
    return _view;
  }

  const decoder = new TextDecoder();

  return {
    addToImports(imports: WebAssembly.Imports): void {
      const wasiImport = imports.wasi_snapshot_preview1 as {
        fd_write: (
          fd: number,
          iovs: number,
          iovsLen: number,
          nwritten: number,
        ) => number;
        fd_filestat_get: (fd: number, filestat: number) => number;
        fd_fdstat_get: (fd: number, fdstat: number) => number;
      };
      const original_fd_write = wasiImport.fd_write;
      wasiImport.fd_write = (fd, iovs, iovsLen, nwritten): number => {
        if (fd !== 1 && fd !== 2) {
          return original_fd_write(fd, iovs, iovsLen, nwritten);
        }

        const view = getMemoryView();
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

      const original_fd_filestat_get = wasiImport.fd_filestat_get;
      wasiImport.fd_filestat_get = (fd, filestat): number => {
        if (fd !== 1 && fd !== 2) {
          return original_fd_filestat_get(fd, filestat);
        }

        const view = getMemoryView();
        const result = original_fd_filestat_get(fd, filestat);
        if (result !== 0) {
          return result;
        }

        const filetypePtr = filestat + 0;
        view.setUint8(filetypePtr, 2); // FILETYPE_CHARACTER_DEVICE

        return 0;
      };

      const original_fd_fdstat_get = wasiImport.fd_fdstat_get;
      wasiImport.fd_fdstat_get = (fd, fdstat): number => {
        if (fd !== 1 && fd !== 2) {
          return original_fd_fdstat_get(fd, fdstat);
        }

        const view = getMemoryView();

        const fs_filetypePtr = fdstat + 0;
        view.setUint8(fs_filetypePtr, 2); // FILETYPE_CHARACTER_DEVICE

        const fs_rights_basePtr = fdstat + 8;
        // See https://github.com/WebAssembly/WASI/blob/v0.2.0/legacy/preview1/docs.md#record-members
        const RIGHTS_FD_WRITE = 1 << 6;
        view.setBigUint64(fs_rights_basePtr, BigInt(RIGHTS_FD_WRITE), true);

        return 0;
      };
    },
    setMemory(m: WebAssembly.Memory) {
      memory = m;
    },
  };
}
