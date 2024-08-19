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

    const fixturesPattern = /fixtures\/(.+)/;
    context.route(fixturesPattern, (route) => {
      const subPath = route.request().url().match(fixturesPattern)[1];
      const mockedPath = path.join("./test-e2e/integrations/fixtures", subPath);

      route.fulfill({
        path: mockedPath,
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

    test("JS::RequireRemote#load recursively loads dependencies", async ({
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
        module Kernel
          def require_relative(path) = JS::RequireRemote.instance.load(path)
        end

        require_relative 'fixtures/recursive_require'
        JS.global.checkResolved RecursiveRequire::B.new.message
      </script>
     `);

      expect(await resolve()).toBe("Hello from RecursiveRequire::B");
    });

    test("JS::RequireRemote#load loads the file with a path relative to the base_url specified by the base_url property.", async ({
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
        JS::RequireRemote.instance.base_url = 'fixtures/recursive_require'
        JS::RequireRemote.instance.load 'b'
        JS.global.checkResolved RecursiveRequire::B.new.message
      </script>
     `);

      expect(await resolve()).toBe("Hello from RecursiveRequire::B");
    });
  });
}
