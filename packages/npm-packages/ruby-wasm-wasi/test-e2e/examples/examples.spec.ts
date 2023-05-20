import { test, expect, Page } from '@playwright/test';

test.beforeEach(async ({ context }) => {
  if (process.env.DEBUG) {
    context.on('request', request => console.log('>>', request.method(), request.url()));
    context.on('response', response => console.log('<<', response.status(), response.url()));
    context.on("console", msg => console.log("LOG:", msg.text()))
  }
})

const waitForRubyVM = async (page: Page) => {
  await page.waitForFunction(() => window["rubyVM"])
}

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
