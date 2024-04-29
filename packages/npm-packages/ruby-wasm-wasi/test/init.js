import * as fs from "fs/promises";
import * as path from "path";
import { WASI } from "wasi";
import { RubyVM } from "../src/index";
import * as preview2Shim from "@bytecodealliance/preview2-shim"

const rubyModule = (async () => {
  let binaryPath;
  if (process.env.RUBY_ROOT) {
    binaryPath = path.join(process.env.RUBY_ROOT, "./usr/local/bin/ruby");
  } else if (process.env.RUBY_NPM_PACKAGE_ROOT) {
    binaryPath = path.join(
      process.env.RUBY_NPM_PACKAGE_ROOT,
      "./dist/ruby.debug+stdlib.wasm",
    );
  } else {
    throw new Error("RUBY_ROOT or RUBY_NPM_PACKAGE_ROOT must be set");
  }
  const binary = await fs.readFile(binaryPath);
  return await WebAssembly.compile(binary.buffer);
})();

const initModuleRubyVM = async ({ suppressStderr } = { suppressStderr: false }) => {
  let preopens = {};
  if (process.env.RUBY_ROOT) {
    preopens["/usr"] = path.join(process.env.RUBY_ROOT, "./usr");
  }
  let stderrFd = 2;
  if (suppressStderr) {
    const devNullFd = await fs.open("/dev/null", "w");
    stderrFd = devNullFd.fd;
  }
  const wasi = new WASI({
    version: "preview1",
    returnOnExit: true,
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    stderr: stderrFd,
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

const moduleCache = new Map();
async function initComponentRubyVM({ suppressStderr } = { suppressStderr: false }) {
  const pkgPath = process.env.RUBY_NPM_PACKAGE_ROOT
  if (!pkgPath) {
    throw new Error("RUBY_NPM_PACKAGE_ROOT must be set");
  }
  const componentJsPath = path.resolve(pkgPath, "dist/component/ruby.component.js");
  const { instantiate } = await import(componentJsPath);
  const getCoreModule = async (relativePath) => {
    const coreModulePath = path.resolve(pkgPath, "dist/component", relativePath);
    if (moduleCache.has(coreModulePath)) {
      return moduleCache.get(coreModulePath);
    }
    const buffer = await fs.readFile(coreModulePath);
    const module = WebAssembly.compile(buffer);
    moduleCache.set(coreModulePath, module);
    return module;
  }
  const vm = await RubyVM._instantiate(async (jsRuntime) => {
    const { cli, clocks, filesystem, io, random, sockets } = preview2Shim;
    filesystem._setPreopens({})
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
  }, {})
  return vm;
}

const initRubyVM = async ({ suppressStderr } = { suppressStderr: false }) => {
  if (process.env.ENABLE_COMPONENT_TESTS && process.env.ENABLE_COMPONENT_TESTS !== 'false') {
    return initComponentRubyVM({ suppressStderr });
  }
  return initModuleRubyVM({ suppressStderr });
}

class RubyVersion {
  constructor(version) {
    this.version = version;
  }

  toComponents() {
    const parts = this.version.split(".").map((x) => parseInt(x, 10));
    // Fill in missing parts with 0 until we have major, minor, and tiny.
    while (parts.length < 3) {
      parts.push(0);
    }
    return parts;
  }

  isGreaterThanOrEqualTo(other) {
    const a = this.toComponents();
    if (!(other instanceof RubyVersion)) {
      other = new RubyVersion(other);
    }
    const b = other.toComponents();
    for (let i = 0; i < 3; i++) {
      if (a[i] > b[i]) {
        return true;
      }
      if (a[i] < b[i]) {
        return false;
      }
    }
    return true;
  }
}

const rubyVersion = (async () => {
  const vm = await initRubyVM({ suppressStderr: true });
  const result = vm.eval("RUBY_VERSION");
  return new RubyVersion(result.toString());
})();

module.exports = { initRubyVM, rubyVersion };
