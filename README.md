# ruby.wasm

[![Build ruby.wasm](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml)

ruby.wasm is a collection of WebAssembly ports of the [CRuby](https://github.com/ruby/ruby).
It enables running Ruby application on browsers, WASI compatible WebAssembly runtimes, and Edge Computing platforms.

## Try ruby.wasm (no installation needed)

Try ruby.wasm in [TryRuby](https://try.ruby-lang.org/playground#code=puts+RUBY_DESCRIPTION&engine=cruby-3.2.0dev) in your browser.

## Quick Links

- [Cheat Sheet](https://github.com/ruby/ruby.wasm/blob/main/docs/cheat_sheet.md)
- [FAQ](https://github.com/ruby/ruby.wasm/blob/main/docs/faq.md)
- [API Reference](https://github.com/ruby/ruby.wasm/blob/main/docs/api.md)
- [Complete Examples](https://github.com/ruby/ruby.wasm/tree/main/packages/npm-packages/ruby-wasm-wasi/example)
- [Community Showcase](https://github.com/ruby/ruby.wasm/wiki/Showcase)

## Quick Example: Ruby on browser

Create and save `index.html` page with the following contents:

```html
<html>
  <script src="https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.5.0/dist/browser.script.iife.js"></script>
  <script type="text/ruby">
    require "js"

    puts RUBY_VERSION # => Hello, world! (printed to the browser console)
    JS.global[:document].write "Hello, world!"
  </script>
</html>
```

## Quick Example: How to package your Ruby application as a WASI application

Dependencies: [wasmtime](https://github.com/bytecodealliance/wasmtime)

```console
$ gem install ruby_wasm
# Download a prebuilt Ruby release
$ curl -LO https://github.com/ruby/ruby.wasm/releases/latest/download/ruby-3.3-wasm32-unknown-wasip1-full.tar.gz
$ tar xfz ruby-3.3-wasm32-unknown-wasip1-full.tar.gz

# Extract ruby binary not to pack itself
$ mv ruby-3.3-wasm32-unknown-wasip1-full/usr/local/bin/ruby ruby.wasm

# Put your app code
$ mkdir src
$ echo "puts 'Hello'" > src/my_app.rb

# Pack the whole directory under /usr and your app dir
$ rbwasm pack ruby.wasm --dir ./src::/src --dir ./ruby-3.3-wasm32-unknown-wasip1-full/usr::/usr -o my-ruby-app.wasm

# Run the packed scripts
$ wasmtime my-ruby-app.wasm /src/my_app.rb
Hello
```

## npm packages (for JavaScript host environments)

See the `README.md` of each package for more detail and its usage.

<table>
  <thead>
    <tr>
      <th>Package</th>
      <th>Description</th>
      <th>npm</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="/packages/npm-packages/ruby-3.3-wasm-wasi">@ruby/3.3-wasm-wasi</a></td>
      <td>CRuby 3.3 built on WASI with JS interop support</td>
      <td><a href="https://www.npmjs.com/package/@ruby/3.3-wasm-wasi" rel="nofollow"><img src="https://badge.fury.io/js/@ruby%2F3.3-wasm-wasi.svg" alt="npm version" style="max-width: 100%;"></a></td>
    </tr>
    <tr>
      <td><a href="/packages/npm-packages/ruby-3.2-wasm-wasi">@ruby/3.2-wasm-wasi</a></td>
      <td>CRuby 3.2 built on WASI with JS interop support</td>
      <td><a href="https://www.npmjs.com/package/@ruby/3.2-wasm-wasi" rel="nofollow"><img src="https://badge.fury.io/js/@ruby%2F3.2-wasm-wasi.svg" alt="npm version" style="max-width: 100%;"></a></td>
    </tr>
    <tr>
      <td><a href="/packages/npm-packages/ruby-head-wasm-wasi">@ruby/head-wasm-wasi</a></td>
      <td>HEAD CRuby built on WASI with JS interop support</td>
      <td><a href="https://www.npmjs.com/package/@ruby/head-wasm-wasi" rel="nofollow"><img src="https://badge.fury.io/js/@ruby%2Fhead-wasm-wasi.svg" alt="npm version" style="max-width: 100%;"></a></td>
    </tr>
    <tr>
      <td><a href="/packages/npm-packages/ruby-head-wasm-emscripten">@ruby/head-wasm-emscripten</a></td>
      <td>HEAD CRuby built on Emscripten (not well tested)</td>
      <td><a href="https://www.npmjs.com/package/@ruby/head-wasm-emscripten" rel="nofollow"><img src="https://badge.fury.io/js/@ruby%2Fhead-wasm-emscripten.svg" alt="npm version" style="max-width: 100%;"></a></td>
    </tr>
  </tbody>
</table>

## Prebuilt binaries

This project distributes [prebuilt Ruby binaries in GitHub Releases](https://github.com/ruby/ruby.wasm/releases).
A _build_ is a combination of ruby version, _profile_, and _target_.

### Supported Target Triples

<table>
  <thead>
    <tr>
      <th>Triple</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>wasm32-unknown-wasip1</code></td>
      <td>Targeting <a href="https://github.com/WebAssembly/WASI/tree/main/legacy/preview1">WASI Preview1</a> compatible environments <br>(e.g. Node.js, browsers with polyfill, <a href="https://github.com/bytecodealliance/wasmtime">wasmtime</a>, and so on)</td>
    </tr>
    <tr>
      <td><code>wasm32-unknown-emscripten</code></td>
      <td>Targeting JavaScript environments including Node.js and browsers</td>
    </tr>
  </tbody>
</table>

### Profiles

<table>
  <thead>
    <tr>
      <th>Profile</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>minimal</code></td>
      <td>No standard extension libraries (like <code>json</code>, <code>yaml</code>, or <code>stringio</code>)</td>
    </tr>
    <tr>
      <td><code>full</code></td>
      <td>All standard extension libraries</td>
    </tr>
  </tbody>
</table>

## Notable Limitations

The current WASI target build does not yet support `Thread` related APIs. Specifically, WASI does not yet have an API for creating and managing threads yet.

Also there is no support for networking. It is one of the goal of WASI to support networking in the future, but it is not yet implemented.


## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to build and test, and how to contribute to this project.
Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/ruby.wasm
