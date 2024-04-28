import { test, expect, Page } from "@playwright/test";

import {
  setupDebugLog,
  setupProxy,
  setupUncaughtExceptionRejection,
  resolveBinding,
} from "../support";

if (!process.env.RUBY_NPM_PACKAGE_ROOT) {
  test.skip("skip", () => {});
} else {
  test.beforeEach(async ({ context, page }) => {
    setupDebugLog(context);
    setupProxy(context);
    setupUncaughtExceptionRejection(page);
  });

  test.describe('WASI browser binding', () => {
    test("Read/write on in-memory file system", async ({ page }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
      require "js"
      File.write("hello.txt", "Hello, world!")
      JS.global.checkResolved File.read("hello.txt")
      </script>
    `);
      expect(await resolve()).toBe("Hello, world!");
    });
  });
}
