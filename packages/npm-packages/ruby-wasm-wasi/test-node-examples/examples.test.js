import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { setupNodeExampleTest } from "./support.js";

describe("Node.js examples", () => {
  let context;

  beforeEach(async () => {
    context = await setupNodeExampleTest();
  });

  afterEach(async () => {
    await context?.cleanup();
  });

  test("index.node.js is healthy", async () => {
    const { stdout } = await context.run("index.node.js");

    expect(stdout).toMatch(/ruby .* \[wasm32-wasi\]/);
    expect(stdout).toContain("NoMethodError");
    expect(stdout).toContain("RuntimeError");
  }, 70_000);
});
