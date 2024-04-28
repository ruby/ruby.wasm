import { initRubyVM } from "./init";
import { describe, test, expect } from "vitest"

describe("Ruby code evaluation", () => {
  test("empty expression", async () => {
    const vm = await initRubyVM();
    const result = vm.eval("");
    expect(result.toString()).toBe("");
  });
});
