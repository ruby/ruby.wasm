import { initRubyVM } from "./init";
import { describe, test, expect } from "vitest"

describe("Async Ruby code evaluation", () => {
  test("async eval over microtasks", async () => {
    const vm = await initRubyVM();
    const result = await vm.evalAsync(`
    require 'js'
    o = JS.eval(<<~JS)
      return {
        async_func: () => {
          return new Promise((resolve) => {
            queueMicrotask(() => {
              resolve(42)
            });
          });
        }
      }
    JS
    o.async_func.await
    `);
    expect(result.toString()).toBe("42");
  });

  test("async eval multiple times", async () => {
    const vm = await initRubyVM();
    vm.eval(`require "js"`);
    const ret0 = await vm.evalAsync(`JS.global[:Promise].resolve(42).await`);
    expect(ret0.toString()).toBe("42");
    const ret1 = await vm.evalAsync(`JS.global[:Promise].resolve(43).await`);
    expect(ret1.toString()).toBe("43");
  });

  test("call async Ruby method from JS", async () => {
    const vm = await initRubyVM();
    const x = vm.eval(`
      class X
        def async_method
          JS.global[:Promise].resolve(42).await
        end
        def async_method_with_args(a, b)
          JS.global[:Promise].resolve(a + b).await
        end
      end
      X.new
    `);

    const ret1 = await x.callAsync("async_method");
    expect(ret1.toString()).toBe("42");

    const ret2 = await x.callAsync(
      "async_method_with_args",
      vm.eval("1"),
      vm.eval("2"),
    );
    expect(ret2.toString()).toBe("3");
  });

  test("await outside of evalAsync or callAsync", async () => {
    const vm = await initRubyVM();
    expect(() => {
      vm.eval(`require "js"; JS.global[:Promise].resolve(42).await`);
    }).toThrow(
      "JS::Object#await can be called only from RubyVM#evalAsync or RbValue#callAsync JS API",
    );

    const x = vm.eval(`
      class X
        def async_method
          JS.global[:Promise].resolve(42).await
        end
      end
      X.new
    `);
    expect(() => x.call("async_method")).toThrow(
      "JS::Object#await can be called only from RubyVM#evalAsync or RbValue#callAsync JS API",
    );
  });
});
