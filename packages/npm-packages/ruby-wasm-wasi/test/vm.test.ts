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

  test("eval encoding", async () => {
    const vm = await initRubyVM();
    expect(vm.eval(`Encoding.default_external.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`"hello".encoding.name`).toString()).toBe("UTF-8");
    expect(vm.eval(`__ENCODING__.name`).toString()).toBe("UTF-8");
  });

  // FIXME: The below two tests are now failing because we cannot make it safe
  // to call eval within eval.
  // See https://github.com/ruby/ruby.wasm/issues/219#issuecomment-1551758711
  test.failing("Nested Fiber switch", async () => {
    const vm = await initRubyVM();
    const setVM = vm.eval(`proc { |vm| JS::RubyVM = vm }`)
    setVM.call("call", vm.wrap(vm))
    vm.eval(`
    $f0 = Fiber.new {
      JS::RubyVM.eval("$f1.resume")
    }
    $f1 = Fiber.new {}
    $f0.resume
    `)
    vm.eval(`puts $q.inspect`)
  })

  test.failing("raise in nested eval", async () => {
    const vm = await initRubyVM();
    const setVM = vm.eval(`proc { |vm| JS::RubyVM = vm }`)
    setVM.call("call", vm.wrap(vm))
    expect(() => {
      vm.eval(`JS::RubyVM.eval("raise 'Exception from nested eval'")`)
    }).toThrowError("Exception from nested eval")
  })
});
