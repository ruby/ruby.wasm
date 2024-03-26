#!/bin/sh
":" //# ; exec /usr/bin/env node --experimental-wasi-unstable-preview1 "$0" "$@"

import * as browserWasi from "@bjorn3/browser_wasi_shim";
import fs from "fs/promises";
import path from "path";
import * as nodeWasi from "wasi";
import { RubyVM, consolePrinter } from "@ruby/wasm-wasi";

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
    version: "preview1",
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

  const __root__ = new browserWasi.Directory({});
  const writeMemFs = (guestPath, contents) => {
    const dirname = path.dirname(guestPath);
    const parts = dirname.split('/');
    let current = __root__;
    for (let i = 1; i < parts.length; i++) {
      const dir = current.create_entry_for_path(parts[i], /* is_dir */ true);
      current = dir;
    }
    const basename = path.basename(guestPath);
    const file = current.create_entry_for_path(basename, /* is_dir */ false)
    file.data = contents;
  };
  const loadToMemFs = async (guestPath, hostPath) => {
    const hostFiles = await walk(hostPath);
    await Promise.all(hostFiles.map(async hostFile => {
      const guestFile = path.join(guestPath, path.relative(hostPath, hostFile));
      const contents = await fs.readFile(hostFile);
      writeMemFs(guestFile, contents);
    }));
  };

  const dirname = path.dirname(new URL(import.meta.url).pathname);
  await loadToMemFs('/test', path.join(dirname, '../test'));

  const { binaryPath } = deriveRubySetup();

  if (process.env.RUBY_ROOT) {
    console.error('For now, testing with RUBY_ROOT is not supported.');
  }

  const binary = await fs.readFile(binaryPath);
  const rubyModule = await WebAssembly.compile(binary);

  const args = ["ruby.wasm"].concat(process.argv.slice(2));
  const env = Object.entries({
    ...process.env,
    // Extend fiber stack size to be able to run test-unit
    "RUBY_FIBER_MACHINE_STACK_SIZE": String(1024 * 1024 * 20),
  }).map(([key, value]) => `${key}=${value}`);


  const fds = [
    new browserWasi.OpenFile(new browserWasi.File([])),
    new browserWasi.OpenFile(new browserWasi.File([])),
    new browserWasi.OpenFile(new browserWasi.File([])),
    new browserWasi.PreopenDirectory("/__root__", __root__.contents)
  ]

  const wasi = new browserWasi.WASI(args, env, fds, {
    debug: false,
  });

  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  const printer = consolePrinter({
    stdout: (str) => process.stdout.write(str),
    stderr: (str) => process.stderr.write(str),
  });
  printer.addToImports(imports);
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);
  printer.setMemory(instance.exports.memory);
  await vm.setInstance(instance);

  wasi.initialize(instance);
  vm.initialize(["ruby.wasm", rootTestFile]);

  return { instance, vm, wasi };
};

const test = async (instantiate) => {
  const rootTestFile = "/__root__/test/test_unit.rb";
  const { vm, wasi } = await instantiate(rootTestFile);

  Error.stackTraceLimit = Infinity;

  await vm.evalAsync(`
    require 'test/unit'
    require_relative '${rootTestFile}'
    ok = Test::Unit::AutoRunner.run
    exit(1) unless ok
  `);
};

const main = async () => {
  await test(instantiateNodeWasi);
  if (!process.env.RUBY_ROOT) {
    await test(instantiateWasmerWasi);
  }
};

main();
