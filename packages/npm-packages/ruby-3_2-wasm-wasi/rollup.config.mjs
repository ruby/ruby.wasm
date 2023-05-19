import json from "@rollup/plugin-json";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import fs from "fs";
import path from "path";

/** @type {import('rollup').RollupOptions[]} */
export default [
  {
    input: "src/browser.script.js",
    output: [
      {
        file: "dist/browser.script.iife.js",
        format: "iife",
        banner: "/* " + fs.readFileSync(path.resolve("../../../NOTICE"), "utf8") + "*/",
      }
    ],
    plugins: [json(), nodeResolve()],
  },
];
