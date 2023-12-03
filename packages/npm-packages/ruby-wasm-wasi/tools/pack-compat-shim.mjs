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

const dirname = path.dirname(new URL(import.meta.url).pathname);

const shimContent = (target, pkg) => {
  const deprecated = target.deprecated ?? true;
  const file = target.file;
  const stem = path.basename(file).replace(`.js`, "");
  const importPath = stem === "index" ? "" : `/dist/${stem}`;
  const deprecationMessage = (original, replacement) => {
    return (
      `DEPRECATED(${pkg}): "dist/${stem}" will be moved to "@ruby/wasm-wasi" in the next major release.\n` +
      `Please replace your \\\`${original}\\\` with \\\`${replacement}\\\``
    );
  };

  let originalImport = "";
  let newImport = "";
  let content = "";
  switch (target.format) {
    case "cjs":
      originalImport = `require('${pkg}${importPath}');`;
      newImport = `require('@ruby/wasm-wasi${importPath}');`;
      content = `module.exports = require('@ruby/wasm-wasi${importPath}');`;
      break;
    case "umd":
      originalImport = `require('${pkg}${importPath}');`;
      newImport = `require('@ruby/wasm-wasi${importPath}');`;
      content = fs.readFileSync(
        path.join(dirname, "..", "dist", file),
        "utf-8",
      );
      break;
    case "esm":
      originalImport = `import * from '${pkg}${importPath}';`;
      newImport = `import * from '@ruby/wasm-wasi${importPath}';`;
      content = `export * from '@ruby/wasm-wasi${importPath}';`;
      break;
    default:
      throw new Error(`Unknown suffix: ${suffix} for target ${file}`);
  }

  if (!deprecated) {
    return content;
  }
  const deprecation =
    "\x1b[33m" + deprecationMessage(originalImport, newImport) + "\x1b[0m";
  return `console.warn(\`${deprecation}\`);\n\n${content}`;
};

const main = () => {
  const targets = [
    { format: "cjs", file: "cjs/browser.js" },
    // They can be used by dynamic-import or <script> tag in browser
    // and there is no easy way to replace them with `@ruby/wasm-wasi`
    // so we don't deprecate them at this moment.
    { format: "esm", file: "esm/browser.js", deprecated: false },
    { format: "umd", file: "browser.umd.js", deprecated: false },

    { format: "cjs", file: "cjs/browser.script.js" },
    { format: "esm", file: "esm/browser.script.js" },
    { format: "umd", file: "browser.script.umd.js" },

    { format: "cjs", file: "cjs/index.js" },
    { format: "esm", file: "esm/index.js" },
    { format: "umd", file: "index.umd.js" },

    { format: "cjs", file: "cjs/node.js" },
    { format: "esm", file: "esm/node.js" },
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
