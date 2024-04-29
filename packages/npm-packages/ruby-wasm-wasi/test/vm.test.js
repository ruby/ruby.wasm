import { initRubyVM, rubyVersion } from "./init";
import { describe, test, expect, vi } from "vitest"

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
      "2",
    );
    expect(
      X.call("take_two", vm.eval(`"x"`), vm.eval(`"y"`)).toString(),
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
    const expectedBacktrace = ((await rubyVersion).isGreaterThanOrEqualTo("3.4.0"))
      ? `eval:9:in 'Object#fizz': fizz raised (RuntimeError)
eval:6:in 'Object#bar'
eval:3:in 'Object#foo'
eval:11:in '<main>'`
      : `eval:9:in \`fizz': fizz raised (RuntimeError)
eval:6:in \`bar'
eval:3:in \`foo'
eval:11:in \`<main>'`
    expect(throwError).toThrowError(expectedBacktrace);
  });

  test.skipIf(
    // TODO(katei): Investigate further why this test "crashes" on Node.js 22.
    process.versions.node.startsWith("22.") && !process.env.ENABLE_COMPONENT_TESTS,
  )("exception while formatting exception backtrace", async () => {
    const vm = await initRubyVM({ suppressStderr: true });
    const throwError = () => {
      vm.eval(`
      class BrokenException < Exception
        def to_s
          raise "something went wrong in BrokenException#to_s"
        end
        def backtrace
          raise "something went wrong in BrokenException#backtrace"
        end
      end
      raise BrokenException.new
      `);
    };
    expect(throwError).toThrowError(`BrokenException: unknown`);
  });

  test("eval encoding", async () => {
    const vm = await initRubyVM();
    expect(vm.eval(`Encoding.default_external.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`"hello".encoding.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`__ENCODING__.name`).toString()).toBe("UTF-8");
  });

  test.each([
    `JS::RubyVM.eval('Fiber.yield')`,
    `
    $f0 = Fiber.new {
      JS::RubyVM.eval("$f1.resume")
    }
    $f1 = Fiber.new {}
    $f0.resume
    `,
    `JS::RubyVM.eval("raise 'Exception from nested eval'")`,
  ])("nested VM rewinding operation should throw fatal error", async (code) => {
    const vm = await initRubyVM({ suppressStderr: true });
    const setVM = vm.eval(`proc { |vm| JS::RubyVM = vm }`);
    setVM.call("call", vm.wrap(vm));
    expect(() => {
      vm.eval(code);
    }).toThrowError("Ruby APIs that may rewind the VM stack are prohibited");
  });

  test.skipIf(
    // TODO(katei): Investigate further why this test "crashes" on Node.js 22.
    process.versions.node.startsWith("22.") && !process.env.ENABLE_COMPONENT_TESTS,
  ).each([`JS::RubyVM.evalAsync("")`])(
    "nested VM rewinding operation should throw fatal error (async)",
    async (code) => {
      // Supress bugreport message triggered by the fatal error inside evalAsync
      const vm = await initRubyVM({ suppressStderr: true });
      const setVM = vm.eval(`proc { |vm| JS::RubyVM = vm }`);
      setVM.call("call", vm.wrap(vm));

      const rejections = [];
      const _evalAsync = vm.evalAsync;
      const spy = vi.spyOn(vm, "evalAsync").mockImplementation((code) => {
        const promise = _evalAsync.call(vm, code).catch((e) => {
          rejections.push(e);
        });
        return promise
      })
      await vm.evalAsync(code)
      spy.mockReset();

      expect(rejections[0].message).toMatch(
        "Ruby APIs that may rewind the VM stack are prohibited",
      );
    },
  );

  test("caught raise in nested eval is ok", async () => {
    const vm = await initRubyVM({ suppressStderr: true });
    const setVM = vm.eval(`proc { |vm| JS::RubyVM = vm }`);
    setVM.call("call", vm.wrap(vm));
    expect(() => {
      vm.eval(
        `JS::RubyVM.eval("begin; raise 'Exception from nested eval'; rescue; end")`,
      );
    }).not.toThrowError();
  });
});
