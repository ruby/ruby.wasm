import { test, expect } from "@playwright/test";
import path from "path";
import { setupProxy, waitForRubyVM } from "../support";

const loaderUrl =
  "https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@latest/dist/browser.script.iife.js";
const pageUrl = "https://example.test/app/index.html";

test.skip(!process.env.RUBY_NPM_PACKAGE_ROOT, "Requires a Ruby npm package");

// Preview 2 loads a component directory rather than a single Ruby WASM file.
test.skip(
  process.env.RUBY_NPM_PACKAGE_ROOT?.includes("wasip2") ?? false,
  "Only supported by Preview 1",
);

test.beforeEach(async ({ context }) => {
  setupProxy(context);
});

test("uses the default CDN when the attribute is omitted", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  page.on("pageerror", (error) => {
    throw error;
  });
  await page.route(pageUrl, (route) =>
    route.fulfill({
      contentType: "text/html",
      body: `<script src="${loaderUrl}" ></script>`,
    }),
  );
  await page.goto(pageUrl);
  await waitForRubyVM(page);
  expect(wasmRequests).toHaveLength(1);
  expect(wasmRequests[0]).toMatch(
    /^https:\/\/cdn\.jsdelivr\.net\/.*\/ruby\+stdlib\.wasm$/,
  );
  expect(
    await page.evaluate(() => window["rubyVM"].eval("21 * 2").toString()),
  ).toBe("42");
});

test("resolves a relative URL against the HTML page and starts Ruby", async ({
  page,
}) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  page.on("pageerror", (error) => {
    throw error;
  });
  const customUrl = "https://example.test/app/ruby-with-custom-gems.wasm";
  await page.route(customUrl, (route) =>
    route.fulfill({
      path: path.join(
        process.env.RUBY_NPM_PACKAGE_ROOT!,
        "dist/ruby+stdlib.wasm",
      ),
      contentType: "application/wasm",
    }),
  );
  await page.route(pageUrl, (route) =>
    route.fulfill({
      contentType: "text/html",
      body: `<script src="${loaderUrl}" data-ruby-wasm-url="./ruby-with-custom-gems.wasm"></script>`,
    }),
  );
  await page.goto(pageUrl);
  await waitForRubyVM(page);
  expect(wasmRequests).toEqual([customUrl]);
  expect(
    await page.evaluate(() => window["rubyVM"].eval("21 * 2").toString()),
  ).toBe("42");
});

test("loads an absolute URL and starts Ruby", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  page.on("pageerror", (error) => {
    throw error;
  });
  const customUrl = "https://binaries.test/custom.wasm";
  await page.route(customUrl, (route) =>
    route.fulfill({
      path: path.join(
        process.env.RUBY_NPM_PACKAGE_ROOT!,
        "dist/ruby+stdlib.wasm",
      ),
      contentType: "application/wasm",
    }),
  );
  await page.route(pageUrl, (route) =>
    route.fulfill({
      contentType: "text/html",
      body: `<script src="${loaderUrl}" data-ruby-wasm-url="https://binaries.test/custom.wasm"></script>`,
    }),
  );
  await page.goto(pageUrl);
  await waitForRubyVM(page);
  expect(wasmRequests).toEqual([customUrl]);
  expect(
    await page.evaluate(() => window["rubyVM"].eval("21 * 2").toString()),
  ).toBe("42");
});

test("rejects an empty URL before fetching", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url=""></script>`,
  );
  expect((await error).message).toContain(
    "data-ruby-wasm-url must be non-empty",
  );
  expect(wasmRequests).toEqual([]);
});

test("rejects a whitespace-only URL before fetching", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url=" "></script>`,
  );
  expect((await error).message).toContain(
    "data-ruby-wasm-url must be non-empty",
  );
  expect(wasmRequests).toEqual([]);
});

test("rejects leading whitespace before fetching", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url=" ./custom.wasm"></script>`,
  );
  expect((await error).message).toContain(
    "data-ruby-wasm-url must be non-empty",
  );
  expect(wasmRequests).toEqual([]);
});

test("rejects trailing whitespace before fetching", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url="./custom.wasm "></script>`,
  );
  expect((await error).message).toContain(
    "data-ruby-wasm-url must be non-empty",
  );
  expect(wasmRequests).toEqual([]);
});

test("rejects a tab-only URL before fetching", async ({ page }) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url="&#9;"></script>`,
  );
  expect((await error).message).toContain(
    "data-ruby-wasm-url must be non-empty",
  );
  expect(wasmRequests).toEqual([]);
});

test("does not fall back to the CDN after a fetch failure", async ({
  page,
}) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const customUrl = "https://example.test/broken.wasm";
  await page.route(customUrl, (route) => route.abort());
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url="${customUrl}"></script>`,
  );
  await error;
  expect(wasmRequests).toEqual([customUrl]);
  expect(await page.evaluate(() => window["rubyVM"])).toBeUndefined();
});

test("does not fall back to the CDN after a compile failure", async ({
  page,
}) => {
  const wasmRequests: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith(".wasm")) wasmRequests.push(request.url());
  });
  const customUrl = "https://example.test/broken.wasm";
  await page.route(customUrl, (route) =>
    route.fulfill({
      contentType: "application/wasm",
      body: "invalid wasm",
    }),
  );
  const error = page.waitForEvent("pageerror");
  await page.setContent(
    `<script src="${loaderUrl}" data-ruby-wasm-url="${customUrl}"></script>`,
  );
  await error;
  expect(wasmRequests).toEqual([customUrl]);
  expect(await page.evaluate(() => window["rubyVM"])).toBeUndefined();
});
