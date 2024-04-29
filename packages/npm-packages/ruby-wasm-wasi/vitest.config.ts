import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    pool: "forks",
    poolOptions: {
      forks: {
        execArgv: ["--experimental-wasi-unstable-preview1", "--expose-gc"],
      }
    },
    testTimeout: 300000,
    exclude: [],
  },
})
