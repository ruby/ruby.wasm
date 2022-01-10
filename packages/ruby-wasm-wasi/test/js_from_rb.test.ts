import { initRubyVM } from "./init";

describe("Manipulation of JS from Ruby", () => {
  const Qtrue = 0x02;
  test(`require "js"`, async () => {
    const vm = await initRubyVM();
    const result = vm.eval(`require "js"`);
    expect((result as any).inner._wasm_val).toBe(Qtrue);
  });

  test.each([
    // A ruby object always returns false
    { object: "1", klass: "Integer", result: false },
    { object: "'x'", klass: "String", result: false },
    // A js object is not an instance of itself
    { object: "JS.global", klass: "JS.global", result: false },
    // globalThis is an instance of Object
    { object: "JS.global", klass: "JS.global[:Object]", result: true },
  ])("JS.is_a? %s", async (props) => {
    const vm = await initRubyVM();
    const code = `require "js"; JS.is_a?(${props.object}, ${props.klass})`;
    expect(vm.eval(code).toString()).toBe(String(props.result));
  });

  test.each([
    { expr: "JS.global[:Object]", result: Object },
    { expr: "JS.global[:Object][:keys]", result: Object.keys },
    { expr: "JS.global[:Object][:unknown_key]", result: undefined },
    // reflect `Reflect` itself
    { expr: "JS.global[:Reflect]", result: Reflect },
  ])(`JS::Object#[] (%s)`, async (props) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      ${props.expr}
    `);
    expect(result.toJS()).toBe(props.result);
  });

  test.each([
    { key: "foo", rvalue: `JS.eval("return 1")`, rvalue_js: 1 },
    { key: "bar", rvalue: `JS.eval("return {}")`, rvalue_js: {} },
  ])(`JS::Object#[]= (%s)`, async (props) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      obj = JS.eval("return {}")
      obj[:${props.key}] = ${props.rvalue}
      obj
    `);
    expect(result.toJS()[props.key]).toEqual(props.rvalue_js);
  });

  test.each([
    { expr: "", result: undefined },
    { expr: "return undefined", result: undefined },
    { expr: "return null", result: null },
    { expr: "return Object", result: Object },
    { expr: "return 1", result: 1 },
    { expr: "return 'x'", result: "x" },
  ])(`JS.eval(%s)`, async (props) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      JS.eval("${props.expr}")
    `);
    expect(result.toJS()).toBe(props.result);
  });

  test.each([
    { expr: `JS.global.call(:Array)`, result: [] },
    { expr: `JS.global.call(:parseInt, JS.eval("return '42'"))`, result: 42 },
    {
      expr: `JS.global.call(:parseInt, JS.eval("return 'ff'"), JS.eval("return 16"))`,
      result: 0xff,
    },
    { expr: `JS.global[:Math].call(:abs, JS.eval("return -1"))`, result: 1 },
    {
      expr: `JS.global[:Math].call(:min, JS.eval("return 1"), JS.eval("return 2"))`,
      result: 1,
    },
  ])(`JS::Object#call (%s)`, async (props) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      ${props.expr}
    `);
    expect(result.toJS()).toEqual(props.result);
  });

  test("invalid JS::Object#call", async () => {
    const vm = await initRubyVM();
    vm.eval("require 'js'");

    expect(() => {
      vm.eval(`JS.global.call(:unknown)`);
    }).toThrow("which is a undefined and not a function");

    expect(() => {
      vm.eval(`JS.global.call(:Object, Object.new)`);
    }).toThrow("argument 2 is not a JS::Object like object");
  });

  test.each([
    { expr: `JS.eval("return {}")`, result: {} },
    { expr: `JS.eval("return 1")`, result: 1 },
    { expr: `1`, result: 1 },
    { expr: `true`, result: true },
    { expr: `false`, result: false },
    { expr: `"x"`, result: "x" },
    { expr: `"x\\0x"`, result: "x\0x" },
  ])("RbValue.toJS(%s)", async (props) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      ${props.expr}
    `);
    expect(result.toJS()).toEqual(props.result);
  });

  test.each([`Object.new`])(
    "invalid RbValue.toJS(%s)",
    async (expr) => {
      const vm = await initRubyVM();
      const result = vm.eval(`
      require "js"
      ${expr}
      `);
      expect(result.toJS()).toEqual(null);
    }
  );
});
