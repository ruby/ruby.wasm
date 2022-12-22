import { RbValue } from "../src/index";
import { initRubyVM } from "./init";

describe("RubyVM", () => {
  test("empty expression", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("");
    expect(result.toString()).toBe("");
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
  test("Integer toPrimitive", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("1");
    expect(result[Symbol.toPrimitive]("string")).toBe("1");
    expect(result + "x").toBe("1x");
    expect(`${result}`).toBe("1");
    // FIXME(katei): support to number primitive?
    expect(result[Symbol.toPrimitive]("number")).toBe(null);
    expect(+result).toBe(0);
  });
  test("String toPrimitive", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("'x'");
    expect(result[Symbol.toPrimitive]("string")).toBe("x");
    expect(result + "x").toBe("xx");
    expect(`${result}`).toBe("x");
    expect(result[Symbol.toPrimitive]("number")).toBe(null);
    expect(+result).toBe(0);
  });
  test("Boolean toPrimitive", async () => {
    const vm = await initRubyVM();
    expect(vm.eval("true").toString()).toBe("true");
    expect(vm.eval("false").toString()).toBe("false");
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
    function dropRbValue(value: RbValue) {
      (value as any).inner.drop();
    }
    const vm = await initRubyVM();
    const initialGCCount = Number(vm.eval("GC.count").toString());
    const robj = vm.eval("$x = Object.new");
    const robjId = robj.call("object_id").toString();
    expect(robjId).not.toEqual("");

    vm.eval("GC.start");
    expect(robj.call("object_id").toString()).toBe(robjId);
    expect(Number(vm.eval("GC.count").toString())).toEqual(initialGCCount + 1);

    const robj2 = vm.eval("$x");
    vm.eval("GC.start");
    expect(robj2.call("object_id").toString()).toBe(robjId);

    const robj3 = robj2.call("itself");
    vm.eval("GC.start");
    expect(robj3.call("object_id").toString()).toBe(robjId);

    dropRbValue(robj);
    expect(robj2.call("object_id").toString()).toBe(robjId);
    expect(robj3.call("object_id").toString()).toBe(robjId);

    vm.eval("GC.start");
    expect(robj2.call("object_id").toString()).toBe(robjId);
    expect(robj3.call("object_id").toString()).toBe(robjId);

    dropRbValue(robj2);
    dropRbValue(robj3);

    vm.eval("GC.start");
  });

  test("method call with args", async () => {
    const vm = await initRubyVM();
    const X = vm.eval(`
    module X
        def self.identical(x)
            x
        end
        def self.take_two(x, y)
            x + y
        end
    end
    X
    `);
    expect(X.call("identical", vm.eval("1")).toString()).toEqual("1");
    expect(X.call("take_two", vm.eval("1"), vm.eval("1")).toString()).toEqual(
      "2"
    );
    expect(
      X.call("take_two", vm.eval(`"x"`), vm.eval(`"y"`)).toString()
    ).toEqual("xy");
  });

  test("exception backtrace", async () => {
    const vm = await initRubyVM();
    const throwError = () => {
      vm.eval(`
        def foo
            bar
        end
        def bar
            fizz
        end
        def fizz
            raise "fizz raised"
        end
        foo
        `);
    };
    expect(throwError)
      .toThrowError(`eval:9:in \`fizz': fizz raised (RuntimeError)
eval:6:in \`bar'
eval:3:in \`foo'
eval:11:in \`<main>'`);
  });

  test("protect objects having same hash values from GC", async () => {
    const vm = await initRubyVM();
    vm.eval(`
    class X
      def hash
        42
      end
      def eql?(other)
        true
      end
    end
    `);

    const o1 = vm.eval(`X.new`);
    const o2 = vm.eval(`X.new`);
    const o3 = vm.eval(`X.new`);
    vm.eval(`GC.start`);
    expect(o1.call("hash").toString()).toBe(o2.call("hash").toString());
    expect(o2.call("hash").toString()).toBe(o3.call("hash").toString());
  });

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

  test("eval encoding", async () => {
    const vm = await initRubyVM();
    expect(vm.eval(`Encoding.default_external.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`"hello".encoding.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`__ENCODING__.name`).toString()).toBe("UTF-8");
  });
});
