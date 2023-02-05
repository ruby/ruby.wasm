
import { Buffer } from "buffer";

import { main } from "../../ruby-wasm-wasi/dist/browser.script.esm"
import * as pkg from "../package.json"

// Since `Buffer.from` is used by `@wasmer/wasi`,
// we export `Buffer` class into the global.
globalThis.Buffer = Buffer;

main(pkg)
