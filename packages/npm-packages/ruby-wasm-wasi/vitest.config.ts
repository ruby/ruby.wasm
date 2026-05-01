import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    pool: "forks",
    poolOptions: {
      forks: {
        execArgv: ["--expose-gc"],
      }
    },
    testTimeout: 300000,
    exclude: [],
  },
})
