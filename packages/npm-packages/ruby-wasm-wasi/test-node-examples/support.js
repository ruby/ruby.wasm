import { execFile } from "child_process";
import fs from "fs/promises";
import os from "os";
import path from "path";
import { promisify } from "util";
import { fileURLToPath } from "url";

const execFileAsync = promisify(execFile);
const exampleDir = fileURLToPath(new URL("../example/", import.meta.url));

export const setupNodeExampleTest = async () => {
  if (!process.env.RUBY_NPM_PACKAGE_ROOT) {
    throw new Error("RUBY_NPM_PACKAGE_ROOT must be set");
  }

  const rubyPackageRoot = path.resolve(process.env.RUBY_NPM_PACKAGE_ROOT);
  const temporaryDir = await fs.mkdtemp(
    path.join(os.tmpdir(), "ruby-wasm-node-example-"),
  );
  const packageLink = path.join(
    temporaryDir,
    "node_modules/@ruby/head-wasm-wasi",
  );

  try {
    await fs.mkdir(path.dirname(packageLink), { recursive: true });
    await fs.symlink(rubyPackageRoot, packageLink, "dir");
  } catch (error) {
    await fs.rm(temporaryDir, { recursive: true, force: true });
    throw error;
  }

  return {
    run: (exampleFile) =>
      execFileAsync(process.execPath, [path.join(exampleDir, exampleFile)], {
        cwd: temporaryDir,
        timeout: 60_000,
      }),
    cleanup: () => fs.rm(temporaryDir, { recursive: true, force: true }),
  };
};
