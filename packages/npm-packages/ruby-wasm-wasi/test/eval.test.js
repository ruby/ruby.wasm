const { initRubyVM } = require("./init");

describe("Ruby code evaluation", () => {
  test("empty expression", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("");
    expect(result.toString()).toBe("");
  });
});
