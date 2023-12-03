import json from "@rollup/plugin-json";
import inject from "@rollup/plugin-inject";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import nodePolyfills from "rollup-plugin-polyfill-node";
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
    plugins: [
      nodePolyfills(),
      inject({ Buffer: ["buffer", "Buffer"] }),
      json(), nodeResolve()
    ],
  },
];
