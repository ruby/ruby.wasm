import { initRubyVM } from "./../init";

describe("JS::Object", () => {
  jest.setTimeout(10 /*sec*/ * 1000);
  describe("#method_missing", () => {
    test("raise NoMethodError if method is not defined in JS", async () => {
      const vm = await initRubyVM();
      const obj = vm.eval(`
                require 'js'
                obj = JS.eval(<<~JS)
                    return { foo() { return true; } };
                JS
            `);
      expect(() => obj.call("bar")).toThrowError();
    });
  });
});
