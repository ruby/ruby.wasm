/*
 * This script generates TypeScript bindings from the WIT definitions
 * in the js gem.
 */
import { fileURLToPath } from "url";
import { generateTypes, $init } from "../../../../node_modules/@bytecodealliance/jco/obj/js-component-bindgen-component.js";
import path from "path"
import fs from "fs/promises"

async function main() {
  const selfPath = fileURLToPath(import.meta.url)
  const witDir = path.resolve(path.join(
    selfPath,
    "../../../../gems/js/wit"
  ))
  await $init
  console.log(`Generating TypeScript bindings from ${witDir}`)
  const generated = generateTypes("ruby", {
    wit: {
      tag: "dir",
      val: witDir
    },
    world: "ext",
    tlaCompat: true
  })
  const bindgenDir = path.join(selfPath, "../../src/bindgen")
  for (const [name, content] of generated) {
    if (name == "ruby.d.ts") {
      console.log(`Skipping ${name}`)
      continue;
    }

    const filePath = path.join(bindgenDir, name)
    console.log(`Writing ${filePath}`)
    await fs.mkdir(path.dirname(filePath), { recursive: true })
    await fs.writeFile(filePath, content)
  }
}

await main()
