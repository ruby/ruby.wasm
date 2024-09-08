import { BrowserContext, Page, expect } from "@playwright/test";
import { readFileSync } from "fs";
import path from "path";

export const waitForRubyVM = async (page: Page) => {
  await page.waitForFunction(() => window["rubyVM"]);
};

export const setupDebugLog = (context: BrowserContext) => {
  if (process.env.DEBUG) {
    context.on("request", (request) =>
      console.log(">>", request.method(), request.url()),
    );
    context.on("response", (response) =>
      console.log("<<", response.status(), response.url()),
    );
    context.on("console", (msg) => console.log("LOG:", msg.text()));
  }
};

export const setupProxy = (context: BrowserContext) => {
  const injectingPkgPath = process.env.RUBY_NPM_PACKAGE_ROOT;
  const injectingPkg = JSON.parse(
      readFileSync(path.join(injectingPkgPath, "package.json"), "utf-8"),
  );
  const cdnPattern = new RegExp(
    `cdn.jsdelivr.net/npm/${injectingPkg.name}@.+/dist/(.+)`
  );
  context.route(cdnPattern, (route) => {
    const request = route.request();
    console.log(">> [MOCK]", request.method(), request.url());
    const relativePath = request.url().match(cdnPattern)[1];
    const mockedPath = path.join(
      injectingPkgPath,
      "dist",
      relativePath,
    );

    route.fulfill({
      path: mockedPath,
    });
  });
};

export const { setupUncaughtExceptionRejection, expectUncaughtException } =
  (() => {
    const rejectUncaughtException = (err: Error) => {
      expect(err).toEqual(undefined);
    };
    return {
      setupUncaughtExceptionRejection: (page: Page) => {
        page.on("pageerror", rejectUncaughtException);
      },
      expectUncaughtException: (page: Page) => {
        page.off("pageerror", rejectUncaughtException);
      },
    };
  })();

export const resolveBinding = async (page: Page, name: string) => {
  let checkResolved;
  const resolvedValue = new Promise((resolve) => {
    checkResolved = resolve;
  });
  await page.exposeBinding(name, async (source, v) => {
    checkResolved(v);
  });
  return async () => await resolvedValue;
};
