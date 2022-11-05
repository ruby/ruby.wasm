#!/bin/sh
":" //# ; exec /usr/bin/env node --experimental-wasi-unstable-preview1 "$0" "$@"

import fs from "fs/promises";
import path from "path";
import { WASI } from "wasi";
import { RubyVM } from "../dist/index.cjs.js";

const instantiate = async (rootTestFile) => {
  const dirname = path.dirname(new URL(import.meta.url).pathname);
  let binaryPath;
  let preopens = {
    __root__: path.join(dirname, ".."),
  };
  if (process.env.RUBY_ROOT) {
    binaryPath = path.join(process.env.RUBY_ROOT, "./usr/local/bin/ruby");
    preopens["/usr"] = path.join(process.env.RUBY_ROOT, "./usr");
  } else {
    binaryPath = path.join(dirname, "../dist/ruby+stdlib.wasm");
  }
  const binary = await fs.readFile(binaryPath);
  const rubyModule = await WebAssembly.compile(binary);
  const wasi = new WASI({
    stdio: "inherit",
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    env: {
      ...process.env,
      // Extend fiber stack size to be able to run test-unit
      "RUBY_FIBER_MACHINE_STACK_SIZE": String(1024 * 1024 * 20),
    },
    preopens: preopens,
  });

  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };

  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);
  await vm.setInstance(instance);

  wasi.initialize(instance);

  vm.initialize(["ruby.wasm", rootTestFile]);
  return { instance, vm };
};

const main = async () => {
  const rootTestFile = "/__root__/test/test_unit.rb";
  const { vm } = await instantiate(rootTestFile);

  Error.stackTraceLimit = Infinity;

  // FIXME: require 'test/unit' fails with evalAsync due to Kernel#eval (?)
  vm.eval(`
    # HACK: Until we've fixed the issue in the test-unit or power_assert
    # See https://github.com/test-unit/test-unit/pull/221
    module Kernel
      alias test_unit_original_require require

      def require(path)
        if path == "power_assert"
          raise LoadError, "power_assert is not supported in this environment"
        end
        test_unit_original_require(path)
      end
    end

    require 'test/unit'
  `);
  await vm.evalAsync(`
    require_relative '${rootTestFile}'
    Test::Unit::AutoRunner.run
  `);
};

main();
