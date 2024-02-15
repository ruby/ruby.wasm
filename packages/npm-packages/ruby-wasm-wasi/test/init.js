const fs = require("fs/promises");
const path = require("path");
const { WASI } = require("wasi");
const { RubyVM } = require("../dist/cjs/index");

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

const initRubyVM = async ({ suppressStderr } = { suppressStderr: false }) => {
  let preopens = {};
  if (process.env.RUBY_ROOT) {
    preopens["/usr"] = path.join(process.env.RUBY_ROOT, "./usr");
  }
  const wasi = new WASI({
    args: ["ruby.wasm"].concat(process.argv.slice(2)),
    stderr: suppressStderr ? 0 : 2,
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
