import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from '@rollup/plugin-node-resolve';

function variant(basename, opts = {}) {
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
    plugins: [typescript({ tsconfig: "./tsconfig.json" }), nodeResolve()],
    ...opts,
  };
}

/** @type {import('rollup').RollupOptions[]} */
export default [
  variant("index"),
  variant("default/browser"),
  {
    input: `src/default/node.ts`,
    output: [
      {
        file: `dist/default/node.esm.js`,
        format: "es",
        name: "ruby-wasm-wasi",
      },
      {
        file: `dist/default/node.cjs.js`,
        format: "cjs",
        exports: "named",
      },
    ],
    plugins: [typescript({ tsconfig: "./tsconfig.json" }), nodeResolve()],
    external: ["wasi"],
  }
];
