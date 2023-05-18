import inject from "@rollup/plugin-inject";
import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import nodePolyfills from "rollup-plugin-polyfill-node";

const typescriptOptions = { tsconfig: "./tsconfig.json", declaration: false };

function variant(basename, { browser = false } = {}) {
  return {
    input: `src/${basename}.ts`,
    output: [
      {
        file: `dist/${basename}.umd.js`,
        format: "umd",
        name: "ruby-wasm-wasi",
      },
      {
        file: `dist/${basename}.esm.js`,
        format: "es",
        name: "ruby-wasm-wasi",
      },
      {
        file: `dist/${basename}.cjs.js`,
        format: "cjs",
        exports: "named",
      },
    ],
    plugins: [
      ...(browser
        ? [nodePolyfills(), inject({ Buffer: ["buffer", "Buffer"] })]
        : []),
      typescript(typescriptOptions),
      nodeResolve(),
    ],
  };
}

/** @type {import('rollup').RollupOptions[]} */
export default [
  variant("index"),
  variant("browser", { browser: true }),
  variant("browser.script", { browser: true }),
  {
    input: `src/node.ts`,
    output: [
      {
        file: `dist/node.esm.js`,
        format: "es",
        name: "ruby-wasm-wasi",
      },
      {
        file: `dist/node.cjs.js`,
        format: "cjs",
        exports: "named",
      },
    ],
    plugins: [typescript(typescriptOptions), nodeResolve()],
    external: ["wasi"],
  },
];
