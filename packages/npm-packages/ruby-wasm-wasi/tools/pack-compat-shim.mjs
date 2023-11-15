#!/usr/bin/env node

import path from "path";
import fs from "fs";

const parseArgs = () => {
  const args = process.argv.slice(2);
  const options = {};
  args.forEach((arg) => {
    const [key, value] = arg.split("=");
    options[key.replace("--", "")] = value;
  });
  return options;
};

const shimContent = (target, pkg) => {
  const deprecated = target.deprecated ?? true;
  const file = target.file;
  const suffix = file.split(".").slice(-2).join(".");
  const deprecationMessage = (original, replacement) => {
    return (
      `DEPRECATED(${pkg}): "${file}" will be moved to "@ruby/wasm-wasi" in the next major release.\n` +
      `Please replace your \\\`${original}\\\` with \\\`${replacement}\\\``
    );
  };

  let originalImport = "";
  let newImport = "";
  switch (suffix) {
    case "cjs.js":
      originalImport = `require('${pkg}/dist/${file}');`;
      newImport = `require('@ruby/wasm-wasi/dist/${file}');`;
      break;
    case "umd.js":
      originalImport = `require('${pkg}/dist/${file}');`;
      newImport = `require('@ruby/wasm-wasi/dist/${file}');`;
      break;
    case "d.ts":
    case "esm.js":
      originalImport = `import * from '${pkg}/dist/${file}';`;
      newImport = `import * from '@ruby/wasm-wasi/dist/${file}';`;
      break;
    default:
      throw new Error(`Unknown suffix: ${suffix} for target ${file}`);
  }

  const dirname = path.dirname(new URL(import.meta.url).pathname);
  const content = fs.readFileSync(
    path.join(dirname, "..", "dist", file),
    "utf-8",
  );
  if (suffix === "d.ts" || !deprecated) {
    return content;
  }
  const deprecation =
    "\x1b[33m" + deprecationMessage(originalImport, newImport) + "\x1b[0m";
  return `console.warn(\`${deprecation}\`);\n\n${content}`;
};

const main = () => {
  const targets = [
    { file: "bindgen/rb-abi-guest.d.ts" },
    { file: "bindgen/rb-js-abi-host.d.ts" },
    { file: "browser.cjs.js" },
    { file: "browser.d.ts" },
    // They can be used by dynamic-import or <script> tag in browser
    // and there is no easy way to replace them with `@ruby/wasm-wasi`
    // so we don't deprecate them at this moment.
    { file: "browser.esm.js", deprecated: false },
    { file: "browser.umd.js", deprecated: false },

    { file: "browser.script.cjs.js" },
    { file: "browser.script.d.ts" },
    { file: "browser.script.esm.js" },
    { file: "browser.script.umd.js" },
    { file: "index.cjs.js" },
    { file: "index.d.ts" },
    { file: "index.esm.js" },
    { file: "index.umd.js" },
    { file: "node.cjs.js" },
    { file: "node.d.ts" },
    { file: "node.esm.js" },
  ];

  const options = parseArgs();
  if (!options.dist || !options.pkg) {
    throw new Error("--dist=path and --pkg=name is required");
  }
  const { dist, pkg } = options;

  for (const target of targets) {
    const shimmed = shimContent(target, pkg);
    const distPath = path.join(dist, target.file);
    fs.mkdirSync(path.dirname(distPath), { recursive: true });
    fs.writeFileSync(distPath, shimmed);
  }
};

main();
