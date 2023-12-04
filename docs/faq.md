[[**Cheat Sheet**]](./cheat_sheet.md)
[[**FAQ**]](./faq.md)
[[**API Reference**]](./api.md)
[[**Complete Examples**]](https://github.com/ruby/ruby.wasm/tree/main/packages/npm-packages/ruby-wasm-wasi/example)
[[**Community Showcase**]](https://github.com/ruby/ruby.wasm/wiki/Showcase)

# FAQ

## Where my `puts` output goes?

By default, `puts` output goes to `STDOUT` which is a JavaScript `console.log` function. You can override it by setting `$stdout` to a Ruby object which has `write` method.

```ruby
$stdout = Object.new.tap do |obj|
  def obj.write(str)
    JS.global[:document].write(str)
  end
end

puts "Hello, world!" # => Prints "Hello, world!" to the HTML document
```

## How to run WebAssembly in Ruby

Use [`wasmtime` Ruby gem](https://rubygems.org/gems/wasmtime).
