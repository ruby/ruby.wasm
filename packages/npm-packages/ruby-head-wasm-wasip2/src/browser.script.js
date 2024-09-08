import { instantiate } from "../dist/component/ruby.component"
import { componentMain } from "@ruby/wasm-wasi/dist/browser.script"
import * as wasip2 from "@bytecodealliance/preview2-shim"
import * as pkg from "../package.json"

componentMain(pkg, { instantiate, wasip2 })
