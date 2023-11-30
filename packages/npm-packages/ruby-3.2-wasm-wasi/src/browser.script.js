import { main } from "@ruby/wasm-wasi/dist/browser.script"
import * as pkg from "../package.json"

main(pkg, {
  env: {
    // WORKAROUND(katei): setjmp consumes a LOT of stack in Ruby 3.2,
    // so we extend default Fiber stack size as well as main stack
    // size allocated by wasm-ld's --stack-size. 8MB is enough for
    // most cases. See https://github.com/ruby/ruby.wasm/issues/273
    "RUBY_FIBER_MACHINE_STACK_SIZE": "8388608"
  }
})
