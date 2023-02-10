import inject from "@rollup/plugin-inject";
import json from "@rollup/plugin-json";
import fs from "fs";
import path from "path";
import nodePolyfills from "rollup-plugin-polyfill-node";

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
      json(),
      nodePolyfills(),
      inject({
        Buffer: ["buffer", "Buffer"],
      }),
    ],
  },
];
