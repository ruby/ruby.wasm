import * as preview2Shim from "@bytecodealliance/preview2-shim"
import * as nodeWasi from "wasi";
import fs from "fs/promises";
import path from "path";
import { RubyVM } from "@ruby/wasm-wasi";
import * as readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import { parseArgs } from "node:util"

async function instantiateComponent(pkgPath) {
  const componentJsPath = path.resolve(pkgPath, "dist/component/ruby.component.js");
  const { instantiate } = await import(componentJsPath);
  const getCoreModule = async (relativePath) => {
    const coreModulePath = path.resolve(pkgPath, "dist/component", relativePath);
    const buffer = await fs.readFile(coreModulePath);
    return WebAssembly.compile(buffer);
  }
  const { cli, filesystem } = preview2Shim;
  cli._setArgs(["ruby.wasm"].concat(process.argv.slice(2)));
  cli._setCwd("/")
  filesystem._setPreopens({})

  const { vm } = await RubyVM.instantiateComponent({
    instantiate, getCoreModule, wasip2: preview2Shim,
  });
  return vm;
}

async function instantiateModule(pkgPath) {
  const binaryPath = path.resolve(pkgPath, "dist/ruby.debug+stdlib.wasm");
  const binary = await fs.readFile(binaryPath);
  const rubyModule = await WebAssembly.compile(binary);
  const wasi = new nodeWasi.WASI({
    stdio: "inherit",
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    env: process.env,
    version: "preview1",
  });

  const { vm } = await RubyVM.instantiateModule({
    module: rubyModule, wasip1: wasi
  })
  return vm;
};

function parseOptions(args) {
  /** @type {import("util").ParseArgsConfig["options"]} */
  const options = {
    pkg: {
      type: "string",
      short: "p",
      default: (() => {
        const dirname = path.dirname(new URL(import.meta.url).pathname);
        return path.resolve(dirname, "../packages/npm-packages/ruby-head-wasm-wasi");
      })()
    },
    type: {
      type: "string",
      short: "t",
      default: "component",
    },
    help: {
      type: "boolean",
      short: "h",
    },
  }
  const { values } = parseArgs({ args, options });
  return values;
}

function printUsage() {
  console.log("Usage: repl.mjs [--pkg <npm-package-path>] [--type <component|module>]");
}

async function main() {
  const args = parseOptions(process.argv.slice(2));
  if (args["help"]) {
    printUsage();
    return;
  }
  const pkgPath = args["pkg"];
  const vm = await (async () => {
    switch (args["type"]) {
      case "component": {
        console.log(`Loading component from ${pkgPath}`);
        return await instantiateComponent(pkgPath);
      }
      case "module": {
        console.log(`Loading core module from ${pkgPath}`);
        return await instantiateModule(pkgPath);
      }
      default:
        throw new Error(`Unknown type: ${args["type"]}`);
    }
  })();
  const rl = readline.createInterface({ input, output });

  vm.eval(`puts RUBY_DESCRIPTION`);

  const printer = vm.eval(`
  class ReplPrinter
    def puts(*args)
      args.each do |arg|
        Kernel.puts(arg)
      end
    end
  end
  ReplPrinter.new
  `);
  while (true) {
    const line = await rl.question(`>> `);
    try {
      const result = vm.eval(line);
      printer.call("puts", result);
    } catch (e) {
      console.error(e);
    }
  }
}

main().catch(console.error);
