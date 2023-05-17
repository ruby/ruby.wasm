import fs from "fs/promises";
import path from "path";
import { WASI } from "wasi";
import { RubyVM } from "../src/index";

const rubyModule = (async () => {
  let binaryPath;
  if (process.env.RUBY_ROOT) {
    binaryPath = path.join(process.env.RUBY_ROOT, "./usr/local/bin/ruby");
  } else {
    binaryPath = path.join(__dirname, "./../dist/ruby+stdlib.wasm");
  }
  const binary = await fs.readFile(binaryPath);
  return await WebAssembly.compile(binary.buffer);
})();

export const initRubyVM = async () => {
  let preopens = {};
  if (process.env.RUBY_ROOT) {
    preopens["/usr"] = path.join(process.env.RUBY_ROOT, "./usr");
  }
  const wasi = new WASI({
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    preopens,
  });

  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };

  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(await rubyModule, imports);
  await vm.setInstance(instance);

  wasi.initialize(instance);

  vm.initialize();
  return vm;
};
