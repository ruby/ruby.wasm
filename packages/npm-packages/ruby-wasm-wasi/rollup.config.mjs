import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from "@rollup/plugin-node-resolve";

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
      typescript(typescriptOptions),
      nodeResolve({ resolveOnly: ["@bjorn3/browser_wasi_shim"] }),
    ],
  };
}

/** @type {import('rollup').RollupOptions[]} */
export default [
  { basename: "browser.script" },
  { basename: "browser" },
  { basename: "index" },
].map(config);
