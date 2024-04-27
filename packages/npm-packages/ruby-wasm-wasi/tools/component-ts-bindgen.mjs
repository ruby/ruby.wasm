/*
 * This script generates TypeScript bindings from the WIT definitions
 * in the js gem.
 */
import { fileURLToPath } from "url";
import { types } from "@bytecodealliance/jco";
import path from "path"
import fs from "fs/promises"

async function main() {
  const selfPath = fileURLToPath(import.meta.url)
  const witDir = path.resolve(path.join(
    selfPath,
    "../../../../gems/js/wit"
  ))
  console.log(`Generating TypeScript bindings from ${witDir}`)
  const bindgenDir = path.join(selfPath, "../../src/bindgen")
  const generated = await types(witDir, {
    name: "ruby",
    world: "ext",
    tlaCompat: true,
    outDir: bindgenDir,
  })
  for (const [filePath, content] of Object.entries(generated)) {
    const name = path.basename(filePath)
    if (name == "ruby.d.ts") {
      console.log(`Skipping ${name}`)
      continue;
    }

    console.log(`Writing ${filePath}`)
    await fs.mkdir(path.dirname(filePath), { recursive: true })
    await fs.writeFile(filePath, content)
  }
}

await main()
