import fs from "fs";
import path from "path";
import { test, expect } from "@playwright/test";
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

    context.route(/fixtures/, (route) => {
      const filename = path.basename(route.request().url());
      route.fulfill({
        path: path.join("./test-e2e/integrations/fixtures", filename),
      });
    });

    context.route(/not_found/, (route) => {
      route.fulfill({
        status: 404,
      });
    });

    setupUncaughtExceptionRejection(page);
  });

  test.describe("JS::RequireRemote#load", () => {
    test("JS::RequireRemote#load returns true", async ({ page }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.goto(
        "https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/",
      );
      await page.setContent(`
      <script src="browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
        require 'js/require_remote'
        JS.global.checkResolved JS::RequireRemote.instance.load 'fixtures/error_on_load_twice'
      </script>
     `);

      expect(await resolve()).toBe(true);
    });

    test("JS::RequireRemote#load returns false when same gem is loaded twice", async ({
      page,
    }) => {
      const resolve = await resolveBinding(page, "checkResolved");
      await page.goto(
        "https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/",
      );
      await page.setContent(`
      <script src="browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async">
        require 'js/require_remote'
        JS::RequireRemote.instance.load 'fixtures/error_on_load_twice'
        JS.global.checkResolved JS::RequireRemote.instance.load 'fixtures/error_on_load_twice'
      </script>
     `);

      expect(await resolve()).toBe(false);
    });

    test("JS::RequireRemote#load throws error when gem is not found", async ({
      page,
    }) => {
      expectUncaughtException(page);

      // Opens the URL that will be used as the basis for determining the relative URL.
      await page.goto(
        "https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/",
      );
      await page.setContent(`
      <script src="browser.script.iife.js">
      </script>
      <script type="text/ruby" data-eval="async">
        require 'js/require_remote'
        JS::RequireRemote.instance.load 'not_found'
      </script>
     `);

      const error = await page.waitForEvent("pageerror");
      expect(error.message).toMatch(/cannot load such url -- .+\/not_found.rb/);
    });
  });
}
