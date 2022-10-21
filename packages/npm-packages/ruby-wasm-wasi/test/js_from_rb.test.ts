import { RbValue } from "../src/index";
import { initRubyVM } from "./init";

describe("Manipulation of JS from Ruby", () => {
  jest.setTimeout(10 /*sec*/ * 1000);

  test(`require "js"`, async () => {
    const vm = await initRubyVM();
    const result = vm.eval(`require "js"`);
    expect(result.toString()).toBe("true");
  });

  test("JS::Object#method_missing with block", async () => {
    const vm = await initRubyVM();
    const proc = vm.eval(`
    require "js"
    proc do |obj|
      obj.take_block "x" do |y|
        $y = y
      end
    end
    `);
    const takeBlock = jest.fn((arg1: string, block: (_: any) => void) => {
      expect(arg1).toBe("x");
      block("y");
    });
    proc.call("call", vm.wrap({ take_block: takeBlock }));
    expect(takeBlock).toBeCalled();
    const y = vm.eval(`$y`);
    expect(y.toString()).toBe("y");
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
    { key: "bar", rvalue: `42`, rvalue_js: 42 },
    { key: "bar", rvalue: `"str"`, rvalue_js: "str" },
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
    { expr: "return 'x\\\\0'", result: "x\0" },
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
    {
      expr: `
        function_to_call = JS.eval('return { a: (callback) => { callback(1) } }')
        b = nil
        function_to_call.call(:a, Proc.new { |a| b = a })
        b
      `,
      result: 1,
    },
    {
      expr: `
        function_to_call = JS.eval('return { a: (callback) => { callback(1) } }')
        b = nil
        function_to_call.call(:a) { |a| b = a }
        b
      `,
      result: 1,
    },
    {
      expr: `
        function_to_call = JS.eval('let callback; return { a: (c) => { callback = c }, b: () => { callback(1) } }')
        b = nil
        function_to_call.call(:a) { |a| b = a }
        function_to_call.call(:b)
        b
      `,
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

  test.each([`Object.new`])("invalid RbValue.toJS(%s)", async (expr) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      ${expr}
      `);
    expect(result.toJS()).toEqual(null);
  });

  test.each([
    { expr: `JS.global`, expected: "[object Object]" },
    { expr: `1.to_js`, expected: "1" },
    { expr: `JS.eval("return null")`, expected: "null" },
    { expr: `JS.eval("return undefined")`, expected: "undefined" },
    { expr: `JS.eval("return Symbol('sym')")`, expected: "Symbol(sym)" },
    { expr: `JS.eval("return {}")`, expected: "[object Object]" },
    {
      expr: `JS.eval("class X {}; return new X()")`,
      expected: "[object Object]",
    },
    { expr: `JS.eval("return console")`, expected: "[object console]" },
  ])("invalid RbValue.toJS(%s)", async ({ expr, expected }) => {
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      ${expr}.inspect
      `);
    expect(result.toJS()).toEqual(expected);
  });

  test("Wrap arbitrary Ruby object to JS::Object", async () => {
    const vm = await initRubyVM();
    const results = vm.eval(`
      require "js"
      intrinsics = JS.eval(<<-JS)
        return {
          identity(v) { return v }
        }
      JS
      o1 = Object.new
      o1_clone = intrinsics.call(:identity, JS::Object.wrap(o1))
      [o1.object_id, o1_clone.call("call", "object_id").inspect]
    `);
    const o1 = results.call("at", vm.eval("0"));
    const o1Clone = results.call("at", vm.eval("1"));
    expect(o1.toString()).toEqual(o1Clone.toString());
  });

  test("Wrapped Ruby object should live until wrapper will be released", async () => {
    const vm = await initRubyVM();
    const run = vm.eval(`
      require "js"
      proc do |imports|
        imports.call(:mark_js_object_live, JS::Object.wrap(Object.new))
      end
    `);
    const livingObjects = new Set<RbValue>();
    run.call(
      "call",
      vm.wrap({
        mark_js_object_live: (object: RbValue) => {
          livingObjects.add(object);
        },
      })
    );
    vm.eval("GC.start");
    for (const object of livingObjects) {
      // Ensure that all objects are still alive
      object.call("itself");
    }
  });
});
