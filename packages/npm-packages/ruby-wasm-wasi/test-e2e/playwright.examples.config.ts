import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'examples',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  use: {
    baseURL: 'http://127.0.0.1:8085',
  },
  webServer: {
    command: 'npm run serve:example',
    url: 'http://127.0.0.1:8085',
    reuseExistingServer: !process.env.CI,
  },
});
