import { test, expect, Page } from "@playwright/test";
import path from "path";
import {
  waitForRubyVM,
  setupDebugLog,
  setupProxy,
  setupUncaughtExceptionRejection,
} from "../support";
import { readFileSync } from "fs";
import http from "http";
import https from "https";

const ruby4OrLater = () => {
  const packageName = path.basename(
    process.env.RUBY_NPM_PACKAGE_ROOT ?? "ruby-head-wasm-wasi",
  );
  if (packageName.startsWith("ruby-head-")) {
    return true;
  }

  const match = packageName.match(/^ruby-(\d+)\.(\d+)-wasm-wasi/);
  if (!match) {
    return false;
  }

  return Number(match[1]) >= 4;
};

const wasiPreview1 = () => {
  const packageName = path.basename(
    process.env.RUBY_NPM_PACKAGE_ROOT ?? "ruby-head-wasm-wasi",
  );
  return packageName.endsWith("-wasm-wasi");
};

test.beforeEach(async ({ context, page }) => {
  setupDebugLog(context);
  setupUncaughtExceptionRejection(page);
  if (process.env.RUBY_NPM_PACKAGE_ROOT) {
    setupProxy(context);
  } else {
    console.info("Testing against CDN deployed files");
    const packagePath = path.join(__dirname, "..", "..", "package.json");
    const packageInfo = JSON.parse(readFileSync(packagePath, "utf-8"));
    const version = packageInfo.version;
    const url = `https://registry.npmjs.org/@ruby/head-wasm-wasi/${version}`;
    const response = await new Promise<http.IncomingMessage>(
      (resolve, reject) => {
        https.get(url, resolve).on("error", reject);
      },
    );
    if (response.statusCode == 404) {
      console.log(
        `@ruby/head-wasm-wasi@${version} is not published yet, so skipping CDN tests`,
      );
      test.skip();
    }
  }
});

test("hello.html is healthy", async ({ page }) => {
  const messages: string[] = [];
  page.on("console", (msg) => messages.push(msg.text()));
  await page.goto("/hello.html");

  await waitForRubyVM(page);
  while (!messages.some((msg) => /Hello, world\!/.test(msg))) {
    await page.waitForEvent("console");
  }
});

test("lucky.html is healthy", async ({ page }) => {
  await page.goto("/lucky.html");
  await waitForRubyVM(page);
  await page.getByRole("button", { name: "Draw Omikuji" }).click();
  const result = await page.locator("#result").textContent();

  expect(result).toMatch(/(Lucky|Unlucky)/);
});

test.describe("ruby-box.html", () => {
  // Ruby::Box hooks require/load and copies extension libraries to a temporary
  // file before loading them. The browser WASI Preview 2 setup does not
  // currently provide writable /tmp, so the Ruby::Box example is limited to
  // WASI Preview 1.
  test.skip(
    !ruby4OrLater() || !wasiPreview1(),
    "Ruby::Box browser example requires Ruby 4.0 or later with WASI Preview 1. WASI Preview 2 does not currently provide writable /tmp.",
  );

  test("is healthy", async ({ page }) => {
    await page.goto("/ruby-box.html");
    await waitForRubyVM(page);
    await expect(page.locator("#enabled")).toHaveText(
      "Ruby::Box.enabled?: true",
    );
    await expect(page.locator("#constant")).toHaveText("box::X: 123");
  });
});

test("script-src/index.html is healthy", async ({ page }) => {
  const messages: string[] = [];
  page.on("console", (msg) => messages.push(msg.text()));
  await page.goto("/script-src/index.html");

  await waitForRubyVM(page);
  while (!messages.some((msg) => /Hello, world\!/.test(msg))) {
    await page.waitForEvent("console");
  }
});

// The browser.script.iife.js obtained from CDN does not include the patch to require_relative.
// Skip when testing against the CDN.
if (process.env.RUBY_NPM_PACKAGE_ROOT) {
  test("require_relative/index.html is healthy", async ({ page }) => {
    // Add a listener to detect errors in the page
    page.on("pageerror", (error) => {
      console.log(`page error occurs: ${error.message}`);
    });

    const messages: string[] = [];
    page.on("console", (msg) => messages.push(msg.text()));
    await page.goto("/require_relative/index.html");

    await waitForRubyVM(page);
    while (!messages.some((msg) => /Hello, world\!/.test(msg))) {
      await page.waitForEvent("console");
    }
  });
}
