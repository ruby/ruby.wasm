import fs from "fs/promises";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

// $ node preopens.node.js

const binary = await fs.readFile(
  "./node_modules/@ruby/head-wasm-wasi/dist/ruby.wasm",
);
const module = await WebAssembly.compile(binary);
const { vm } = await DefaultRubyVM(module, {
  preopens: {
    "/app": "./require_relative",
  },
});

// /app/main.rb uses require_relative to load /app/greeting.rb.
vm.eval('require "/app/main"');
vm.eval("$stdout.flush");
