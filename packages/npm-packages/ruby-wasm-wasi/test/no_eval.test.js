import { initRubyVM } from "./init";
import { describe, test, expect, vi, afterEach } from "vitest"

// A page whose Content-Security-Policy lacks 'unsafe-eval' blocks Function(),
// which JS.eval uses. Loading the js gem and converting values must not need it.
describe("without Function()", () => {
  afterEach(() => vi.unstubAllGlobals());

  test("require 'js' and to_js work", async () => {
    vi.stubGlobal("Function", () => {
      throw new EvalError("Function() is blocked");
    });
    const vm = await initRubyVM();
    const result = vm.eval(`
      require "js"
      blocked = begin; JS.eval("return 1"); false; rescue JS::Error; true; end
      [blocked, JS::Undefined.typeof, JS::Null.inspect, JS::True.to_s, JS::False.to_s,
       [1, 2].to_js[:length].to_i, { a: 1 }.to_js[:a].to_i].inspect
    `);
    expect(result.toString()).toBe('[true, "undefined", "null", "true", "false", 2, 1]');
  });
});
