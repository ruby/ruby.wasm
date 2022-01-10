import typescript from "@rollup/plugin-typescript";

/** @type {import('rollup').RollupOptions[]} */
export default {
  input: "src/index.ts",
  output: [
    {
      file: "dist/index.umd.js",
      format: "umd",
      name: "ruby-wasm-wasi",
    },
    {
      file: "dist/index.esm.js",
      format: "es",
      name: "ruby-wasm-wasi",
    },
    {
      file: "dist/index.cjs.js",
      format: "cjs",
      exports: "named",
    },
  ],
  plugins: [typescript()],
};
