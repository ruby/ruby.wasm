#!/bin/sh
":" //# ; exec /usr/bin/env node --experimental-wasi-unstable-preview1 "$0" "$@"

import * as browserWasi from "@bjorn3/browser_wasi_shim";
import * as preview2Shim from "@bytecodealliance/preview2-shim"
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

const instantiateComponent = async (rootTestFile) => {
  const pkgPath = process.env.RUBY_NPM_PACKAGE_ROOT
  if (!pkgPath) {
    throw new Error("RUBY_NPM_PACKAGE_ROOT must be set");
  }
  const componentJsPath = path.resolve(pkgPath, "dist/component/ruby.component.js");
  const { instantiate } = await import(componentJsPath);
  const getCoreModule = async (relativePath) => {
    const coreModulePath = path.resolve(pkgPath, "dist/component", relativePath);
    const buffer = await fs.readFile(coreModulePath);
    return WebAssembly.compile(buffer);
  }
  const vm = await RubyVM._instantiate(async (jsRuntime) => {
    const { cli, clocks, filesystem, io, random, sockets } = preview2Shim;
    const dirname = path.dirname(new URL(import.meta.url).pathname);
    filesystem._setPreopens({
      "/__root__": path.join(dirname, ".."),
    })
    cli._setArgs(["ruby.wasm"].concat(process.argv.slice(2)));
    cli._setCwd("/")
    const root = await instantiate(getCoreModule, {
      "ruby:js/js-runtime": jsRuntime,
      "wasi:cli/environment": cli.environment,
      "wasi:cli/exit": cli.exit,
      "wasi:cli/stderr": cli.stderr,
      "wasi:cli/stdin": cli.stdin,
      "wasi:cli/stdout": cli.stdout,
      "wasi:cli/terminal-input": cli.terminalInput,
      "wasi:cli/terminal-output": cli.terminalOutput,
      "wasi:cli/terminal-stderr": cli.terminalStderr,
      "wasi:cli/terminal-stdin": cli.terminalStdin,
      "wasi:cli/terminal-stdout": cli.terminalStdout,
      "wasi:clocks/monotonic-clock": clocks.monotonicClock,
      "wasi:clocks/wall-clock": clocks.wallClock,
      "wasi:filesystem/preopens": filesystem.preopens,
      "wasi:filesystem/types": filesystem.types,
      "wasi:io/error": io.error,
      "wasi:io/poll": io.poll,
      "wasi:io/streams": io.streams,
      "wasi:random/random": random.random,
      "wasi:sockets/tcp": sockets.tcp,
    })
    return root.rubyRuntime;
  }, {
    args: ["ruby.wasm", rootTestFile],
  })
  return { vm };
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

const instantiateBrowserWasi = async (rootTestFile) => {
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

  const __root__ = new browserWasi.Directory(new Map());
  const writeMemFs = (guestPath, contents) => {
    const dirname = path.dirname(guestPath);
    const parts = dirname.split('/');
    let current = __root__;
    for (let i = 1; i < parts.length; i++) {
      const existing = current.contents.get(parts[i]);
      if (existing) {
        current = existing;
      } else {
        const { entry: created } = current.create_entry_for_path(parts[i], /* is_dir */ true);
        current = created;
      }
    }
    const basename = path.basename(guestPath);
    const { entry: file } = current.create_entry_for_path(basename, /* is_dir */ false)
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


  await vm.evalAsync(`
    require 'test/unit'
    require_relative '${rootTestFile}'
    ok = Test::Unit::AutoRunner.run
    exit(1) unless ok
  `);
};

const main = async () => {
  Error.stackTraceLimit = Infinity;
  if (process.env.ENABLE_COMPONENT_TESTS && process.env.ENABLE_COMPONENT_TESTS !== 'false') {
    await test(instantiateComponent);
  } else {
    await test(instantiateNodeWasi);
    if (!process.env.RUBY_ROOT) {
      await test(instantiateBrowserWasi);
    }
  }
};

main();
