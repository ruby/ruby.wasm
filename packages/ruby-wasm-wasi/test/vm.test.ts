import { RubyVM } from "../dist/index";
import { WASI } from "wasi";
import * as fs from "fs/promises";
import * as path from "path";

const rubyModule = (async () => {
  const binary = await fs.readFile(
    path.join(__dirname, "./../dist/bin/ruby.wasm")
  );
  return await WebAssembly.compile(binary.buffer);
})();

const initRubyVM = async () => {
  const wasi = new WASI();
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(await rubyModule, imports);
  await vm.init(instance);
  wasi.initialize(instance);
  vm.guest.rubyInit();
  const args = ["ruby.wasm\0", "--disable-gems", "-e\0", "_=0\0"];
  vm.guest.rubySysinit(args);
  vm.guest.rubyOptions(args)
  return vm;
};

describe("RubyVM", () => {
  test("empty expression", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("");
    expect(result.rawValue()).toBe(/* Qnil */ 4);
  });
  test("nil toString", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("nil");
    expect(result.toString()).toBe("");
  });
  test("nil toPrimitive", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("nil");
    expect(result[Symbol.toPrimitive]("string")).toBe("");
    expect(result + "x").toBe("x");
    expect(`${result}`).toBe("");
    expect(result[Symbol.toPrimitive]("number")).toBe(null);
    expect(+result).toBe(0);
  });
  test("null continued string", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("1\u00002");
    expect(result.toString()).toBe("1");
  });
  test("non-local exits", async () => {
    const vm = await initRubyVM();
    expect(() => {
      vm.eval(`raise "panic!"`);
    }).toThrowError("panic!");
    expect(() => {
      vm.eval(`throw "panic!"`);
    }).toThrowError("panic!");
    expect(() => {
      vm.eval(`return`);
    }).toThrowError("unexpected return");
    expect(() => {
      vm.eval(`next`);
    }).toThrowError("Can't escape from eval with next");
    expect(() => {
      vm.eval(`redo`);
    }).toThrowError("Can't escape from eval with redo");
  });

  test("protect exported Ruby objects", async () => {
    const vm = await initRubyVM();
    const initialGCCount = Number(vm.eval("GC.count").toString())
    const robj = vm.eval("Object.new");
    const robjId = robj.call("object_id").toString();
    expect(robjId).not.toEqual("");

    vm.eval("GC.start");
    expect(robj.call("object_id").toString()).toBe(robjId);
    expect(Number(vm.eval("GC.count").toString())).toEqual(initialGCCount + 1)
  });
});
