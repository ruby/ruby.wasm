import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    pool: "forks",
    execArgv: ["--expose-gc"],
    testTimeout: 300000,
    exclude: [],
  },
})
