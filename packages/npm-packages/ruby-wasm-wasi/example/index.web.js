import { WASI } from "./node_modules/@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import { DefaultRubyVM } from "ruby-wasm-wasi/dist/default/browser.esm";

const main = async () => {
  // Fetch and instntiate WebAssembly binary
  const response = await fetch("./node_modules/ruby-wasm-wasi/dist/ruby.wasm");
  const buffer = await response.arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const vm = await DefaultRubyVM(module);

  vm.printVersion();

  runRubyScriptsInHtml(vm);
};

const runRubyScriptsInHtml = (vm) => {
  const tags = document.getElementsByTagName("script");
  for (var i = 0, len = tags.length; i < len; i++) {
    const tag = tags[i];
    if (tag.type === "text/ruby") {
      if (tag.innerHTML) {
        vm.eval(tag.innerHTML);
      }
    }
  }
};

main();
