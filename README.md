[![Build ruby.wasm](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/ruby/ruby.wasm/actions/workflows/build.yml)

# ruby.wasm

ruby.wasm is a collection of WebAssembly ports of the [CRuby](https://github.com/ruby/ruby).
It enables running Ruby application on browsers, WASI compatible WebAssembly runtimes, and Edge Computing platforms.

## npm packages (for JavaScript host environments)

See the `README.md` of each package for more detail and its usage.

| Package                                                                        | Description                                      | npm                                                                                                                          |
| ------------------------------------------------------------------------------ | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| [ruby-head-wasm-wasi](./packages/npm-packages/ruby-head-wasm-wasi)             | HEAD CRuby built on WASI with JS interop support | [![npm version](https://badge.fury.io/js/ruby-head-wasm-wasi.svg)](https://badge.fury.io/js/ruby-head-wasm-wasi)             |
| [ruby-head-wasm-emscripten](./packages/npm-packages/ruby-head-wasm-emscripten) | HEAD CRuby built on Emscripten (not well tested) | [![npm version](https://badge.fury.io/js/ruby-head-wasm-emscripten.svg)](https://badge.fury.io/js/ruby-head-wasm-emscripten) |

## Quick Example: How to package your Ruby application as a WASI application

Dependencies: [wasi-vfs](https://github.com/kateinoigakukun/wasi-vfs), [wasmtime](https://github.com/bytecodealliance/wasmtime)

```console
# Download a prebuilt Ruby release
$ curl -LO https://github.com/ruby/ruby.wasm/releases/download/2022-03-28-a/ruby-head-wasm32-unknown-wasi-full.tar.gz
$ tar xfz ruby-head-wasm32-unknown-wasi-full.tar.gz

# Extract ruby binary not to pack itself
$ mv head-wasm32-unknown-wasi-full/usr/local/bin/ruby ruby.wasm

# Put your app code
$ mkdir src
$ echo "puts 'Hello'" > src/my_app.rb

# Pack the whole directory under /usr and your app dir
$ wasi-vfs pack ruby.wasm --mapdir /src::./src --mapdir /usr::./head-wasm32-unknown-wasi-full/usr -o my-ruby-app.wasm

# Run the packed scripts
$ wasmtime my-ruby-app.wasm -- /src/my_app.rb
Hello
```

## Prebuilt binaries

This project distributes [prebuilt Ruby binaries in GitHub Releases](https://github.com/ruby/ruby.wasm/releases).
A _build_ is a combination of ruby version, _profile_, and _target_.

### Supported Target Triples

| Triple                      | Description                                                                                                                                        |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `wasm32-unknown-wasi`       | Targeting WASI-compatible environments (e.g. Node.js, browsers with polyfill, [wasmtime](https://github.com/bytecodealliance/wasmtime), and so on) |
| `wasm32-unknown-emscripten` | Targeting JavaScript environments including Node.js and browsers                                                                                   |

### Profiles

| Profile   | Description                                                                                                                   |
|-----------|-------------------------------------------------------------------------------------------------------------------------------|
| `minimal` | No standard extension libraries (like `json`, `yaml`, or `stringio`)                                                          |
| `full`    | All standard extension libraries                                                                                              |
| `*-js`    | Enabled JS interoperability, only usable with npm package                                                                     |
| `*-debug` | With DWARF info and [`name` section](https://webassembly.github.io/spec/core/appendix/custom.html#name-section) for debugging |

Note: `*` is a wildcard that represents any other profile name except for itself, applied recursively. For example, `minimal-full-js-debug` is a valid profile.

## Building from source

If you want to build Ruby for WebAssembly from source yourself, follow the below instructions.

(However, in most cases, it's easier to use prebuilt binaries instead of building them yourself)

### Dependencies

- [wit-bindgen](https://github.com/bytecodealliance/wit-bindgen): A language bindings generator for `wit` used in the npm packages. Install in `PATH`.
- [wasi-sdk](https://github.com/WebAssembly/wasi-sdk): Only for building for WASI target. Set `WASI_SDK_PATH` environment variable to the directory of wasi-sdk.
- [Binaryen](https://github.com/WebAssembly/binaryen): Only for building for WASI target. Install `wasm-opt` in `PATH`
- [wasi-vfs](https://github.com/kateinoigakukun/wasi-vfs): A virtual filesystem layer for WASI. Install CLI tool in `PATH`. Set `LIB_WASI_VFS_A` environment variable to the path to `libwasi_vfs.a`.
- [wasi-preset-args](https://github.com/kateinoigakukun/wasi-preset-args): A tool to preset command-line arguments to a WASI module. Install in `PATH`.
- [Emscripten](https://emscripten.org): Only for building for Emscripten target. Follow the official instructions to install.

Note: It's recommended building on a builder Docker container, which installs all dependencies and provides environment variables:

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
$ tree -L 3 rubies/head-wasm32-unknown-wasi-full-js
rubies/head-wasm32-unknown-wasi-full-js/
├── usr
│   └── local
│       ├── bin
│       ├── include
│       ├── lib
│       └── share
└── var
    └── lib
        └── gems

# Or build npm package. Output is a tarball of npm package
$ rake npm:ruby-head-wasm-wasi
$ ls packages/npm-packages/ruby-head-wasm-wasi/ruby-head-wasm-wasi-*.tgz
```

## Notable Limitations

The current WASI target build does not yet support `Thread` related APIs. Specifically, WASI does not yet have an API for creating and managing threads yet.

Also there is no support for networking. It is one of the goal of WASI to support networking in the future, but it is not yet implemented.
