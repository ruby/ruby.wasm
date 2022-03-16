import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from '@rollup/plugin-node-resolve';

function variant(basename) {
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
    plugins: [typescript({ tsconfig: "./tsconfig.json", declaration: false }), nodeResolve()],
  };
}

/** @type {import('rollup').RollupOptions[]} */
export default [
  variant("index"),
  variant("browser"),
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
    plugins: [typescript({ tsconfig: "./tsconfig.json", declaration: false }), nodeResolve()],
    external: ["wasi"],
  }
];
