#!/bin/sh
":" //# ; exec /usr/bin/env node --experimental-wasi-unstable-preview1 "$0" "$@"

import * as wasmerWasi from "@wasmer/wasi";
import fs from "fs/promises";
import path from "path";
import * as nodeWasi from "wasi";
import { RubyVM } from "../dist/index.cjs.js";

const deriveRubySetup = () => {
  let preopens = {}
  let binaryPath;
  if (process.env.RUBY_ROOT) {
    binaryPath = path.join(process.env.RUBY_ROOT, "./usr/local/bin/ruby");
    preopens["/usr"] = path.join(process.env.RUBY_ROOT, "./usr");
  } else if (process.env.RUBY_NPM_PACKAGE_ROOT) {
    binaryPath = path.join(process.env.RUBY_NPM_PACKAGE_ROOT, "./dist/ruby.debug+stdlib.wasm");
  } else {
    throw new Error("RUBY_ROOT or RUBY_NPM_PACKAGE_ROOT must be set");
  }
  return { binaryPath, preopens };
}

const instantiateNodeWasi = async (rootTestFile) => {
  const dirname = path.dirname(new URL(import.meta.url).pathname);
  const { binaryPath, preopens } = deriveRubySetup();
  preopens["__root__"] = path.join(dirname, "..");
  const binary = await fs.readFile(binaryPath);
  const rubyModule = await WebAssembly.compile(binary);
  const wasi = new nodeWasi.WASI({
    stdio: "inherit",
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    env: {
      ...process.env,
      // Extend fiber stack size to be able to run test-unit
      "RUBY_FIBER_MACHINE_STACK_SIZE": String(1024 * 1024 * 20),
    },
    preopens,
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
  return { instance, vm, wasi };
};

const instantiateWasmerWasi = async (rootTestFile) => {
  await wasmerWasi.init();

  const memFs = new wasmerWasi.MemFS();
  const walk = async (dir) => {
    const names = await fs.readdir(dir);
    const files = await Promise.all(names.map(async name => {
      if ((await fs.stat(path.join(dir, name))).isDirectory()) {
        return walk(path.join(dir, name));
      } else {
        return [path.join(dir, name)];
      }
    }));
    return files.flat();
  };
  const mkdirpMemFs = (guestPath) => {
    const parts = guestPath.split('/');
    for (let i = 2; i <= parts.length; i++) {
      memFs.createDir(parts.slice(0, i).join('/'));
    }
  };
  const loadToMemFs = async (guestPath, hostPath) => {
    const hostFiles = await walk(hostPath);
    await Promise.all(hostFiles.map(async hostFile => {
      const guestFile = path.join(guestPath, path.relative(hostPath, hostFile));
      mkdirpMemFs(path.dirname(guestFile));
      const contents = await fs.readFile(hostFile);
      memFs.open(guestFile, { write: true, create: true }).write(contents);
    }));
  };

  const dirname = path.dirname(new URL(import.meta.url).pathname);
  await loadToMemFs('/__root__/test', path.join(dirname, '../test'));

  const { binaryPath, preopens } = deriveRubySetup();
  preopens["__root__"] = '/__root__';

  if (process.env.RUBY_ROOT) {
    console.error('For now, testing with RUBY_ROOT is not supported.');
  }

  const binary = await fs.readFile(binaryPath);
  const rubyModule = await WebAssembly.compile(binary);

  const wasi = new wasmerWasi.WASI({
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    env: {
      ...process.env,
      // Extend fiber stack size to be able to run test-unit
      "RUBY_FIBER_MACHINE_STACK_SIZE": String(1024 * 1024 * 20),
    },
    preopens,
    fs: memFs,
  });

  const vm = new RubyVM();
  const imports = wasi.getImports(rubyModule);
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);
  wasi.instantiate(instance);
  await vm.setInstance(instance);

  instance.exports._initialize();
  vm.initialize(["ruby.wasm", rootTestFile]);

  return { instance, vm, wasi };
};

const test = async (instantiate) => {
  const rootTestFile = "/__root__/test/test_unit.rb";
  const { vm, wasi } = await instantiate(rootTestFile);

  Error.stackTraceLimit = Infinity;

  await vm.evalAsync(`
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
    require_relative '${rootTestFile}'
    Test::Unit::AutoRunner.run
  `);

  // TODO(makenowjust): override `wasi_snapshot_preview1.fd_write` for output to stdout/stderr.
  // See `src/browser.ts`.
  if (wasi.getStderrString) {
    console.error(wasi.getStderrString());
  }
  if (wasi.getStdoutString) {
    console.log(wasi.getStdoutString());
  }
};

const main = async () => {
  await test(instantiateNodeWasi);
  await test(instantiateWasmerWasi);
};

main();
