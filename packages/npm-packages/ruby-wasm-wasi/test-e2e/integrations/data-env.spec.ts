import { test, expect } from "@playwright/test";

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

  test.describe("data-env", () => {
    test("passes environment variables to the Ruby VM", async ({ page }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.setContent(`
      <script
        src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js"
        data-env='{"RUBY_WASM_TEST":"ok","RUBY_WASM_TEST_EQUALS":"a=b","RUBY_WASM_TEST_SPACES":"hello world"}'
      ></script>
      <script type="text/ruby" data-eval="async">
      require "js"
      JS.global.checkResolved [ENV["RUBY_WASM_TEST"], ENV["RUBY_WASM_TEST_EQUALS"], ENV["RUBY_WASM_TEST_SPACES"]].join(",")
      </script>
    `);
      expect(await resolve()).toBe("ok,a=b,hello world");
    });
  });
}
