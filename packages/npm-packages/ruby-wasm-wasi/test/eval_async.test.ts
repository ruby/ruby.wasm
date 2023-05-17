import { initRubyVM } from "./init";

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

  test("await outside of evalAsync", async () => {
    const vm = await initRubyVM();
    const result = vm.eval(
      `require "js"; JS.global[:Promise].resolve(42).await`
    );
    expect(result.call("nil?").toString()).toBe("true");
  });
});
