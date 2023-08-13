import { DefaultRubyVM } from "./browser";
import runRubyScriptsInHtml from "./runRubyScriptsInHtml";

export const main = async (pkg: { name: string; version: string }) => {
  const response = await fetch(
    `https://cdn.jsdelivr.net/npm/${pkg.name}@${pkg.version}/dist/ruby+stdlib.wasm`,
  );
  const buffer = await response.arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const { vm } = await DefaultRubyVM(module);

  vm.printVersion();

  globalThis.rubyVM = vm;

  // Wait for the text/ruby script tag to be read.
  // It may take some time to read ruby+stdlib.wasm
  // and DOMContentLoaded has already been fired.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () =>
      runRubyScriptsInHtml(vm),
    );
  } else {
    runRubyScriptsInHtml(vm);
  }
};
