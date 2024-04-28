import { initRubyVM } from "./init";
import { describe, test, expect } from "vitest"

describe("RbValue#toJS", () => {
  test.each([
    { expr: `1`, result: 1 },
    { expr: `true`, result: true },
    { expr: `false`, result: false },
    { expr: `"x"`, result: "x" },
    { expr: `"x\\0x"`, result: "x\0x" },
  ])(`Primitive Ruby object`, async (props) => {
    const vm = await initRubyVM();
    vm.eval(`require "js"; JS`);
    const result = vm.eval(props.expr);
    expect(result.toJS()).toBe(props.result);
  });

  test.each([
    { expr: "", result: undefined },
    { expr: "return undefined", result: undefined },
    { expr: "return null", result: null },
    { expr: "return Object", result: Object },
    { expr: "return 1", result: 1 },
    { expr: "return 'x'", result: "x" },
    { expr: "return 'x\\\\0'", result: "x\0" },
  ])(`Primitive JS object`, async (props) => {
    const vm = await initRubyVM();
    const JS = vm.eval(`require "js"; JS`);
    // TODO(katei): Use RubyVM#toRbValue instead of RubyVM#eval.
    const result = JS.call("eval", vm.eval(`"${props.expr}"`));
    expect(result.toJS()).toBe(props.result);
  });
});
