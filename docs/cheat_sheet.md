[[**Cheat Sheet**]](./cheat_sheet.md)
[[**FAQ**]](./faq.md)
[[**API Reference**]](./api.md)
[[**Complete Examples**]](https://github.com/ruby/ruby.wasm/tree/main/packages/npm-packages/ruby-wasm-wasi/example)
[[**Community Showcase**]](https://github.com/ruby/ruby.wasm/wiki/Showcase)

# ruby.wasm Cheat Sheet

## Node.js

To install the package, install `@ruby/3.3-wasm-wasi` and `@ruby/wasm-wasi` from npm:

```console
npm install --save @ruby/3.3-wasm-wasi @ruby/wasm-wasi
```

Then instantiate a Ruby VM by the following code:

```javascript
import fs from "fs/promises";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

const binary = await fs.readFile("./node_modules/@ruby/3.3-wasm-wasi/dist/ruby.wasm");
const module = await WebAssembly.compile(binary);
const { vm } = await DefaultRubyVM(module);
vm.eval(`puts "hello world"`);
```

Then run the example code with `--experimental-wasi-unstable-preview1` flag to enable WASI support:

```console
$ node --experimental-wasi-unstable-preview1 index.mjs
```

## Browser

The easiest way to run Ruby on browser is to use `browser.script.iife.js` script from CDN:

```html
<html>
  <script src="https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.0/dist/browser.script.iife.js"></script>
  <script type="text/ruby">
    require "js"
    JS.global[:document].write "Hello, world!"
  </script>
</html>
```

If you want to control Ruby VM from JavaScript, you can use `@ruby/wasm-wasi` package API:

```html
<html>
  <script type="module">
    import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.6.0/dist/browser/+esm";
    const response = await fetch("https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.0/dist/ruby+stdlib.wasm");
    const module = await WebAssembly.compileStreaming(response);
    const { vm } = await DefaultRubyVM(module);

    vm.eval(`
      require "js"
      JS.global[:document].write "Hello, world!"
    `);
  </script>
</html>
```

<details>
<summary>Alternative: Without ES Modules</summary>

```html
<html>
  <script src="https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.6.0/dist/browser.umd.js"></script>
  <script>
    const main = async () => {
      const { DefaultRubyVM } = window["ruby-wasm-wasi"];
      const response = await fetch("https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.0/dist/ruby+stdlib.wasm");
      const module = await WebAssembly.compileStreaming(response);
      const { vm } = await DefaultRubyVM(module);

      vm.eval(`
        require "js"
        JS.global[:document].write "Hello, world!"
      `);
    }
    main()
  </script>
</html>
```
</details>

## Use JavaScript from Ruby

### Get/set JavaScript variables from Ruby

```ruby
require "js"

document = JS.global[:document]
document[:title] = "Hello, world!"
```

### Call JavaScript methods from Ruby

```ruby
require "js"

JS.global[:document].createElement("div")

JS.global[:document].call(:createElement, "div".to_js) # same as above
```

### Pass Ruby `Proc` to JavaScript (Callback to Ruby)

```ruby
require "js"

JS.global.setTimeout(proc { puts "Hello, world!" }, 1000)

input = JS.global[:document].querySelector("input")
input.addEventListener("change") do |event|
  puts event[:target][:value].to_s
end
```

### `await` JavaScript `Promise` from Ruby

`data-eval="async"` attribute is required to use `await` in `<script>` tag:

```html
<html>
  <script src="https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.0/dist/browser.script.iife.js"></script>
  <script type="text/ruby" data-eval="async">
    require "js"

    response = JS.global.fetch("https://www.ruby-lang.org/").await
    puts response[:status]
  </script>
</html>
```

Or using `@ruby/wasm-wasi` package API `RubyVM#evalAsync`:

```html
<html>
  <script type="module">
    import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.6.0/dist/browser/+esm";
    const response = await fetch("https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.0/dist/ruby+stdlib.wasm");
    const module = await WebAssembly.compileStreaming(response);
    const { vm } = await DefaultRubyVM(module);

    vm.evalAsync(`
      require "js"

      response = JS.global.fetch("https://www.ruby-lang.org/").await
      puts response[:status]
    `);
  </script>
</html>
```

### `new` JavaScript instance from Ruby

```ruby
require "js"

JS.global[:Date].new(2000, 9, 13)
```

### Convert returned JavaScript `String` value to Ruby `String`

```ruby
require "js"

title = JS.global[:document].title # => JS::Object("Hello, world!")
title.to_s # => "Hello, world!"
```

### Convert JavaScript `Boolean` value to Ruby `true`/`false`

```ruby
require "js"

JS.global[:document].hasFocus? # => true
JS.global[:document].hasFocus  # => JS::Object(true)
```

### Convert JavaScript `Number` value to Ruby `Integer`/`Float`

```ruby
require "js"

rand = JS.global[:Math].random # JS::Object(0.123456789)
rand.to_i # => 0
rand.to_f # => 0.123456789
```
