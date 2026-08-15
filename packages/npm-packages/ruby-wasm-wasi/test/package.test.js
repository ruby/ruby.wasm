import * as path from "path";
import * as fs from "fs/promises";
import * as os from "os";
import { WASI } from "wasi";
import { RubyVM } from "../src/index";
import { DefaultRubyVM } from "../src/node";
import { describe, test, expect } from "vitest"

const initRubyVM = async (rubyModule, args) => {
  const wasi = new WASI({
    version: "preview1",
    returnOnExit: true,
  });
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };

  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(rubyModule, imports);

  await vm.setInstance(instance);

  wasi.initialize(instance);
  vm.initialize();

  return {
    vm,
    wasi,
    instance,
  };
};

describe("Packaging validation", () => {
  if (
    !process.env.RUBY_NPM_PACKAGE_ROOT ||
    (process.env.ENABLE_COMPONENT_TESTS && process.env.ENABLE_COMPONENT_TESTS !== 'false')
  ) {
    test.skip("skip", () => {});
    return;
  }

  const moduleCache = new Map();
  const loadWasmModule = async (file) => {
    if (moduleCache.has(file)) {
      return moduleCache.get(file);
    }
    const binary = await fs.readFile(
      path.join(process.env.RUBY_NPM_PACKAGE_ROOT, `./dist/${file}`),
    );
    const mod = await WebAssembly.compile(binary.buffer);
    moduleCache.set(file, mod);
    return mod;
  };

  test("DefaultRubyVM", async () => {
    const mod = await loadWasmModule(`ruby+stdlib.wasm`);
    const { vm } = await DefaultRubyVM(mod);
    vm.eval(`require "stringio"`);
  });

  test("DefaultRubyVM WASI preopens with require_relative", async () => {
    const mod = await loadWasmModule(`ruby+stdlib.wasm`);
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "ruby-wasm-preopen-"));
    const nestedDir = path.join(tempDir, "nested");
    const entryFile = path.join(tempDir, "entry.rb");
    const helperFile = path.join(nestedDir, "helper.rb");

    try {
      await fs.mkdir(nestedDir);
      await fs.writeFile(entryFile, [
        "PREOPEN_ENTRY_FILE = __FILE__",
        "require_relative './nested/helper'",
      ].join("\n"));
      await fs.writeFile(helperFile, "PREOPEN_HELPER_FILE = __FILE__\n");

      const { vm } = await DefaultRubyVM(mod, {
        preopens: { "/app": tempDir },
      });
      expect(vm.eval(`require "/app/entry"`).toString()).toBe("true");
      expect(vm.eval(`require "/app/entry"`).toString()).toBe("false");

      expect(vm.eval("PREOPEN_ENTRY_FILE").toString()).toBe("/app/entry.rb");
      expect(vm.eval("PREOPEN_HELPER_FILE").toString()).toBe(
        "/app/nested/helper.rb",
      );
      expect(
        vm.eval('$LOADED_FEATURES.include?("/app/entry.rb")').toString(),
      ).toBe("true");
      expect(
        vm
          .eval('$LOADED_FEATURES.include?("/app/nested/helper.rb")')
          .toString(),
      ).toBe("true");
      expect(
        vm
          .eval(`$LOADED_FEATURES.include?(${JSON.stringify(entryFile)})`)
          .toString(),
      ).toBe("false");
      expect(vm.eval(`File.file?(${JSON.stringify(entryFile)})`).toString()).toBe(
        "false",
      );
    } finally {
      await fs.rm(tempDir, { recursive: true, force: true });
    }
  });

  test.each([
    { file: "ruby+stdlib.wasm", stdlib: true },
    { file: "ruby.debug+stdlib.wasm", stdlib: true },
  ])("Load all variants", async ({ file, stdlib }) => {
    const mod = await loadWasmModule(file);
    const { vm } = await initRubyVM(mod, ["ruby.wasm", "-e_=0"]);
    // Check loading ext library
    vm.eval(`require "stringio"`);
    if (stdlib) {
      // Check loading stdlib gem
      vm.eval(`require "English"`);
    }
  });

  test("ruby.debug+stdlib.wasm has debug info", async () => {
    const mod = await loadWasmModule("ruby.debug+stdlib.wasm");
    const nameSections = WebAssembly.Module.customSections(mod, "name");
    expect(nameSections.length).toBe(1);
  });
});
