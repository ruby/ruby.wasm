# How to Contribute

Thank you for your interest in contributing to ruby.wasm!
This document describes development setup and pointers for diving into this project.

## Install dependencies

```console
$ git clone https://github.com/ruby/ruby.wasm
$ cd ruby.wasm
$ bundle install
$ rake --tasks
```

## Building and Testing [`ruby-wasm-wasi`](./packages/ruby-wasm-wasi)

```console
# Download a prebuilt Ruby release (if you don't need to re-build Ruby)
$ rake build:download_prebuilt
# Build npm package
$ rake npm:ruby-head-wasm-wasi
# Test npm package
$ rake npm:ruby-head-wasm-wasi-check
```

## Re-bindgen from `.wit` files

If you update [`*.wit`](https://github.com/WebAssembly/component-model/blob/ed90add27ae845b2e2b9d7db38a966d9f78aa4c0/design/mvp/WIT.md), which describe the interface of a WebAssembly module, either imported or exported, you need to re-generate glue code from `*.wit`.

To re-generate them, you need to install the Rust compiler `rustc` and Cargo, then run `rake check:bindgen`.

The rake task installs [`wit-bindgen`](https://github.com/bytecodealliance/wit-bindgen) on demand, then just execute it for each generated code

If you see `missing executable: cargo`, please make sure `cargo` is installed correctly in your `PATH`.
