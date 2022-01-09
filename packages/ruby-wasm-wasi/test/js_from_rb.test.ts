import { initRubyVM } from "./init";

describe("RubyVM", () => {
  const Qfalse = 0x00;
  const Qtrue = 0x02;
  test(`require "js"`, async () => {
    const vm = await initRubyVM();
    const result = vm.eval(`require "js"`);
    expect((result.inner as any)._wasm_val).toBe(Qtrue);
  });
  test.each([{ object: "1", klass: "Integer", result: false }])(
    "JS.is_a? %s",
    async (props) => {
      const vm = await initRubyVM();
      const code = `require "js"; JS.is_a?(${props.object}, ${props.klass})`;
      expect(vm.eval(code).toString()).toBe(String(props.result));
    }
  );
});
