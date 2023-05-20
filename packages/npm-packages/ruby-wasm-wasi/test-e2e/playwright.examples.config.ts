import { defineConfig } from '@playwright/test';
import base from "./playwright.base.config"

export default defineConfig({
  ...base,
  testDir: 'examples',
  use: {
    baseURL: 'http://127.0.0.1:8085',
  },
  webServer: {
    command: 'npm run serve:example',
    url: 'http://127.0.0.1:8085',
    reuseExistingServer: !process.env.CI,
  },
});
