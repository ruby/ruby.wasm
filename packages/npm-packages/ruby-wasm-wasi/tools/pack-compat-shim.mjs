#!/usr/bin/env node

import path from 'path';
import fs from 'fs';

const parseArgs = () => {
  const args = process.argv.slice(2);
  const options = {};
  args.forEach((arg) => {
    const [key, value] = arg.split('=');
    options[key.replace('--', '')] = value;
  });
  return options;
};

const shimContent = (target, pkg) => {
  const suffix = target.split('.').slice(-2).join('.');
  const deprecationMessage = (original, replacement) => {
    return `DEPRECATED(${pkg}): "${target}" will be moved to "@ruby/wasm-wasi" in the next major release.\n`
      + `Please replace your \\\`${original}\\\` with \\\`${replacement}\\\``;
  };

  let originalImport = '';
  let newImport = '';
  switch (suffix) {
  case 'cjs.js':
    originalImport = `require('${pkg}/dist/${target}');`;
    newImport = `require('@ruby/wasm-wasi/dist/${target}');`;
    break;
  case 'umd.js':
    originalImport = `require('${pkg}/dist/${target}');`;
    newImport = `require('@ruby/wasm-wasi/dist/${target}');`;
    break;
  case 'd.ts':
  case 'esm.js':
    originalImport = `import * from '${pkg}/dist/${target}';`;
    newImport = `import * from '@ruby/wasm-wasi/dist/${target}';`;
    break;
  default:
    throw new Error(`Unknown suffix: ${suffix} for target ${target}`);
  }

  const dirname = path.dirname(new URL(import.meta.url).pathname);
  const content = fs.readFileSync(path.join(dirname, '..', 'dist', target), 'utf-8');
  if (suffix === 'd.ts') {
    return content
  }
  const deprecation = "\x1b[33m" + deprecationMessage(originalImport, newImport) + "\x1b[0m";
  return `console.warn(\`${deprecation}\`);\n\n${content}`;
}

const main = () => {
  const targets = [
    "bindgen/rb-abi-guest.d.ts",
    "bindgen/rb-js-abi-host.d.ts",
    "browser.cjs.js",
    "browser.d.ts",
    "browser.esm.js",
    "browser.script.cjs.js",
    "browser.script.d.ts",
    "browser.script.esm.js",
    "browser.script.umd.js",
    "browser.umd.js",
    "index.cjs.js",
    "index.d.ts",
    "index.esm.js",
    "index.umd.js",
    "node.cjs.js",
    "node.d.ts",
    "node.esm.js",
  ]

  const options = parseArgs();
  if (!options.dist || !options.pkg) {
    throw new Error('--dist=path and --pkg=name is required');
  }
  const { dist, pkg } = options

  for (const target of targets) {
    const shimmed = shimContent(target, pkg);
    const distPath = path.join(dist, target);
    fs.mkdirSync(path.dirname(distPath), { recursive: true });
    fs.writeFileSync(distPath, shimmed);
  }
}

main();
