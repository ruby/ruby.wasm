import json from "@rollup/plugin-json";

/** @type {import('rollup').RollupOptions[]} */
export default [
  {
    input: "src/browser.script.js",
    output: [
      {
        file: "dist/browser.script.iife.js",
        format: "iife"
      }
    ],
    plugins: [
      json(),
    ],
  },
];
