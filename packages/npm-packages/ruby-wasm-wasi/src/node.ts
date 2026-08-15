import { WASI } from "wasi";
import { RubyVM } from "./vm.js";

export const DefaultRubyVM = async (
  rubyModule: WebAssembly.Module,
  options: {
    env?: Record<string, string> | undefined;
    preopens?: Record<string, string>;
  } = {},
) => {
  const wasi = new WASI({
    env: options.env,
    preopens: options.preopens,
    version: "preview1",
    returnOnExit: true,
  });
  const { vm, instance } = await RubyVM.instantiateModule({ module: rubyModule, wasip1: wasi });

  return {
    vm,
    wasi,
    instance,
  };
};
