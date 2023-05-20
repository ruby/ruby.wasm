import { defineConfig } from '@playwright/test';
import base from "./playwright.base.config"

export default defineConfig({
  ...base,
  testDir: 'integrations',
});
