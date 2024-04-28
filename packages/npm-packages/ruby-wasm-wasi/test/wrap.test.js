import { initRubyVM } from "./init";
import { describe, test, expect } from "vitest"

describe("RubyVM#wrap", () => {
  test("Wrap arbitrary JS object to RbValue", async () => {
    const vm = await initRubyVM();
    const o1 = {
      v() {
        return 42;
      },
    };
    const X = vm.eval(`
    module X
      def self.identity(x) = x
    end
    X
    `);
    const o1Clone = X.call("identity", vm.wrap(o1));
    expect(o1Clone.call("call", vm.eval(`"v"`)).toJS().toString()).toBe("42");

    // Check that JS object can be stored in Ruby Hash
    const hash = vm.eval(`Hash.new`);
    hash.call("store", vm.eval(`"key1"`), vm.wrap(new Object()));
  });
});
