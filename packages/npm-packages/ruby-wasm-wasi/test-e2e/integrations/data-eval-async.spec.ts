import { test, expect, Page } from "@playwright/test";

import {
  setupDebugLog,
  setupProxy,
  setupUncaughtExceptionRejection,
  expectUncaughtException,
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

  test.describe('data-eval="async"', () => {
    test("JS::Object#await returns value", async ({ page }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
      require "js"
      JS.global.checkResolved JS.global[:Promise].resolve(42).await
      </script>
    `);
      expect(await resolve()).toBe(42);
    });

    test("JS::Object#await throws error on default attr", async ({ page }) => {
      expectUncaughtException(page);

      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby">
      require "js"
      JS.global[:Promise].resolve(42).await
      </script>
     `);
      const error = await page.waitForEvent("pageerror");
      expect(error.message).toMatch(
        /please ensure that you specify `data-eval="async"`/,
      );
    });

    test("default stack size is enough to require 'json'", async ({ page }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
      require 'json'
      JS.global.checkResolved "ok"
      </script>
     `);
      expect(await resolve()).toBe("ok");
    });
  });
}
