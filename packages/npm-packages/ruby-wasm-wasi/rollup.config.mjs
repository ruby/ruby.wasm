import inject from "@rollup/plugin-inject";
import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import nodePolyfills from "rollup-plugin-polyfill-node";

const typescriptOptions = { tsconfig: "./tsconfig.json", declaration: false };

function config({ basename }) {
  return {
    input: `src/${basename}.ts`,
    output: {
      file: `dist/${basename}.umd.js`,
      format: "umd",
      name: "ruby-wasm-wasi",
    },
    plugins: [
      nodePolyfills(),
      inject({ Buffer: ["buffer", "Buffer"] }),
      typescript(typescriptOptions),
      nodeResolve({ resolveOnly: ["@wasmer/wasi"] })
    ]
  };
}

/** @type {import('rollup').RollupOptions[]} */
export default [
  { basename: "browser.script" },
  { basename: "browser" },
  { basename: "index" },
].map(config);
