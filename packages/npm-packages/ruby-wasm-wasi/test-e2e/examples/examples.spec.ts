import { test, expect, Page } from '@playwright/test';
import path from "path"
import { waitForRubyVM, setupDebugLog, setupProxy } from "../support"

test.beforeEach(async ({ context }) => {
  setupDebugLog(context);
  if (process.env.RUBY_NPM_PACKAGE_ROOT) {
    setupProxy(context);
  } else {
    console.info("Testing against CDN deployed files")
  }
})

test('hello.html is healthy', async ({ page }) => {
  const messages = []
  page.on("console", msg => messages.push(msg.text()))
  await page.goto('/hello.html');

  await waitForRubyVM(page)
  expect(messages[messages.length - 1]).toEqual("Hello, world!\n")
});

test('lucky.html is healthy', async ({ page }) => {
  await page.goto('/lucky.html');
  await waitForRubyVM(page)
  await page.getByRole('button', { name: 'Draw Omikuji' }).click()
  const result = await page.locator("#result").textContent()

  expect(result).toMatch(/(Lucky|Unlucky)/)
});

test('script-src/index.html is healthy', async ({ page }) => {
  const messages = []
  page.on("console", msg => messages.push(msg.text()))
  await page.goto('/script-src/index.html');

  await waitForRubyVM(page)
  const expected = "Hello, world!\n"
  while (messages[messages.length - 1] != expected) {
    await page.waitForEvent("console")
  }
});
