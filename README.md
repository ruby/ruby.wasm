[![Build ruby.wasm](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml)

# ruby.wasm

ruby.wasm is a collection of WebAssembly ports of the [CRuby](https://github.com/ruby/ruby).
It enables running Ruby application on browsers, WASI compatible WebAssembly runtimes, and Edge Computing platforms.

## npm packages (for JavaScript host environments)

| Package                                                                        | Description                                      | npm                                                                                                                          |
| ------------------------------------------------------------------------------ | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| [ruby-head-wasm-wasi](./packages/npm-packages/ruby-head-wasm-wasi)             | HEAD CRuby built on WASI with JS interop support | [![npm version](https://badge.fury.io/js/ruby-head-wasm-wasi.svg)](https://badge.fury.io/js/ruby-head-wasm-wasi)             |
| [ruby-head-wasm-emscripten](./packages/npm-packages/ruby-head-wasm-emscripten) | HEAD CRuby built on Emscripten (not well tested) | [![npm version](https://badge.fury.io/js/ruby-head-wasm-emscripten.svg)](https://badge.fury.io/js/ruby-head-wasm-emscripten) |

## Prebuilt binaries

[The prebuilt binaries are available at here](https://github.com/ruby/ruby.wasm/releases).
A _build_ is a combination of ruby version, _profile_, and _target_.

The supported _target triples_ in this repository are:

- `wasm32-unknown-wasi`
- `wasm32-unknown-emscripten`

### Profiles

| Profile    | Description                                                                          |
| ---------- | ------------------------------------------------------------------------------------ |
| minimal    | No standard extension libraries (like `json`, `yaml`, or `stringio`)                 |
| full       | All standard extension libraries                                                     |
| minimal-js | No standard extension libraries, and usable with npm package (only for WASI target)  |
| full-js    | All standard extension libraries, and usable with npm package (only for WASI target) |

## Building from source

### Dependencies

- [wit-bindgen](https://github.com/bytecodealliance/wit-bindgen): A language bindings generator for `wit` used in the npm packages.
- [wasi-sdk](https://github.com/WebAssembly/wasi-sdk): For building for WASI target. Set `WASI_SDK_PATH` environment variable to the directory of wasi-sdk.
- [wasi-vfs](https://github.com/kateinoigakukun/wasi-vfs): A virtual filesystem layer for WASI.
- [wasi-preset-args](https://github.com/kateinoigakukun/wasi-preset-args): A tool to preset command-line arguments to a WASI module.
- [Emscripten](https://emscripten.org): For building for Emscripten target

It's recommended to build on a Docker container, which installs all dependencies and provides environment variables:

```console
# For building ruby for WASI target
$ docker run -v $(pwd):/src -w /src --rm -it ghcr.io/ruby/ruby.wasm-builder:wasm32-unknown-wasi /bin/bash
# For building ruby for Emscripten target
$ docker run -v $(pwd):/src -w /src --rm -it ghcr.io/ruby/ruby.wasm-builder:wasm32-unknown-emscripten /bin/bash
```

Then, you can build by `rake` command. See `rake -T` for more information.

```console
# Build only a specific combination of ruby version, profile, and target
# Output is in the `rubies` directory
$ rake build:head-wasm32-unknown-wasi-full-js
# Build npm packages and required ruby
$ rake npm:all
```

## Notable Limitations

The current WASI target build does not yet support `Thread` related APIs. Specifically, WASI does not yet have an API for creating and managing threads yet.

Also there is no support for networking. It is one of the goal of WASI to support networking in the future, but it is not yet implemented.
