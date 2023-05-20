import { BrowserContext, Page } from '@playwright/test';
import path from "path"

export const waitForRubyVM = async (page: Page) => {
  await page.waitForFunction(() => window["rubyVM"])
}

export const setupDebugLog = (context: BrowserContext) => {
  if (process.env.DEBUG) {
    context.on('request', request => console.log('>>', request.method(), request.url()));
    context.on('response', response => console.log('<<', response.status(), response.url()));
    context.on("console", msg => console.log("LOG:", msg.text()))
  }
}

export const setupProxy = (context: BrowserContext) => {
  const cdnPattern = /cdn.jsdelivr.net\/npm\/ruby-head-wasm-wasi@.+\/dist\/(.+)/
  context.route(cdnPattern, route => {
    const request = route.request()
    console.log(">> [MOCK]", request.method(), request.url())
    const relativePath = request.url().match(cdnPattern)[1]
    route.fulfill({ path: path.join(process.env.RUBY_NPM_PACKAGE_ROOT, "dist", relativePath) })
  })
}
