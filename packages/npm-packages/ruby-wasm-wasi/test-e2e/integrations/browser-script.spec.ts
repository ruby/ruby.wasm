import { test, expect, Page } from '@playwright/test';

import { setupDebugLog, setupProxy, waitForRubyVM } from "../support"

if (!process.env.RUBY_NPM_PACKAGE_ROOT) {
  test.skip('skip', () => {})
} else {
  test.beforeEach(async ({ context }) => {
    setupDebugLog(context);
    setupProxy(context);
  })

  test.describe('data-eval="async"', () => {
    test("JS::Object#await returns value", async ({ page, context }) => {
      let checkResolved;
      const resolvedValue = new Promise((resolve) => {
        checkResolved = resolve;
      })
      await page.exposeBinding('checkResolved', async (source, v) => {
        checkResolved(v);
      });
      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
      require "js"
      JS.global.checkResolved JS.global[:Promise].resolve(42).await
      </script>
    `)
      expect(await resolvedValue).toBe(42);
    })

    test("JS::Object#await throws error on default attr", async ({ page, context }) => {
      await page.setContent(`
      <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@latest/dist/browser.script.iife.js"></script>
      <script type="text/ruby">
      require "js"
      JS.global[:Promise].resolve(42).await
      </script>
     `)
      const error = await page.waitForEvent("pageerror")
      expect(error.message).toMatch(/please ensure that you specify `data-eval="async"`/)
    })
  })
}
