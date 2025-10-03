# How to Contribute

Thank you for your interest in contributing to ruby.wasm!
This document describes development setup and pointers for diving into this project.

## Install dependencies

```console
$ git clone https://github.com/ruby/ruby.wasm --recursive
$ cd ruby.wasm
$ ./bin/setup
# Compile extension library
$ bundle exec rake compile
$ rake --tasks
```

## Building and Testing [`ruby-wasm-wasi`](./packages/npm-packages/ruby-wasm-wasi)

```console
# Download a prebuilt Ruby release (if you don't need to re-build Ruby)
$ rake build:download_prebuilt

# Build Ruby (if you need to build Ruby by yourself)
$ rake build:head-wasm32-unknown-wasip1-full

# Build npm package
$ rake npm:ruby-head-wasm-wasip2:build
# Test npm package
$ rake npm:ruby-head-wasm-wasip2:check
```

If you need to re-build Ruby, please clean `./rubies` directory, and run `rake npm:ruby-head-wasm-wasi` again.

## Building CRuby from source

If you want to build CRuby for WebAssembly from source yourself, follow the below instructions.

> **Warning**
> If you just want to build npm packages, you don't need to build CRuby from source.
> You can download a prebuilt Ruby release by `rake build:download_prebuilt`.

### For WASI target

You can build CRuby for WebAssembly/WASI on Linux (x86_64) or macOS (x86_64, arm64).
For WASI target, dependencies are automatically downloaded on demand, so you don't need to install them manually.

To select a build profile, see [profiles section in README](https://github.com/ruby/ruby.wasm#profiles).

```console
# Build only a specific combination of ruby version, profile, and target
$ rake build:head-wasm32-unknown-wasip1-full
# Clean up the build directory
$ rake build:head-wasm32-unknown-wasip1-full:clean
# Force to re-execute "make install"
$ rake build:head-wasm32-unknown-wasip1-full:remake

# Output is in the `rubies` directory
$ tree -L 3 rubies/head-wasm32-unknown-wasip1-full
rubies/head-wasm32-unknown-wasip1-full/
├── usr
│   └── local
│       ├── bin
│       ├── include
│       ├── lib
│       └── share
```

### For Emscripten target

To build CRuby for WebAssembly/Emscripten, you need to install [Emscripten](https://emscripten.org).
Please follow the official instructions to install.

```console
# Build only a specific combination of ruby version, profile, and target
$ rake build:head-wasm32-unknown-emscripten-full
# Output is in the `rubies` directory
$ tree -L 3 rubies/head-wasm32-unknown-emscripten-full
rubies/head-wasm32-unknown-emscripten-full
└── usr
    └── local
        ├── bin
        ├── include
        ├── lib
        └── share
```

## Code Formatting

This project uses multiple code formatters for each language.
To format all files, run `rake format`.
Please make sure to run this command before submitting a pull request.

## Re-bindgen from `.wit` files

If you update [`*.wit`](https://github.com/WebAssembly/component-model/blob/ed90add27ae845b2e2b9d7db38a966d9f78aa4c0/design/mvp/WIT.md), which describe the interface of a WebAssembly module, either imported or exported, you need to re-generate glue code from `*.wit`.

To re-generate them, you need to install the Rust compiler `rustc` and Cargo, then run `rake check:bindgen`.

The rake task installs [`wit-bindgen`](https://github.com/bytecodealliance/wit-bindgen) on demand, then just execute it for each generated code

If you see `missing executable: cargo`, please make sure `cargo` is installed correctly in your `PATH`.

## Release Process

To bump up npm package version, please follow the below steps:

```
$ rake 'bump_version[0.6.0]'
$ git commit -m"Bump version to 0.6.0"
$ git tag 0.6.0
$ git push origin 0.6.0
# After GitHub Actions "Build gems" is done
# https://github.com/ruby/ruby.wasm/actions/workflows/build-gems.yml
$ gh run download <run-id>
$ for pkg in cross-gem-*/ruby_wasm-*; do gem push $pkg; done
$ gem build && gem push ruby_wasm-*.gem && rm ruby_wasm-*.gem
$ (cd packages/gems/js/ && gem build && gem push js-*.gem && rm js-*.gem)
$ rake bump_dev_version
```

## Release Channels

Each npm package in this project provides two release channels: `latest` and `next`. The `latest` channel is for stable releases, and `next` channel is for pre-release.

e.g. For [`@ruby/wasm-wasi`](https://www.npmjs.com/package/@ruby/wasm-wasi)

```console
$ npm install --save @ruby/wasm-wasi@latest
# or if you want the nightly snapshot
$ npm install --save @ruby/wasm-wasi@next
# or you can specify the exact snapshot version
$ npm install --save @ruby/wasm-wasi@2.7.2-2025-10-03-a
```


## Adding Support for a New Ruby Version

When a new version of Ruby is released, the following steps need to be taken to add support for it in ruby.wasm:

1. Update `lib/ruby_wasm/cli.rb`:
   - Add a new entry in the `build_source_aliases` method for the new version
   - Specify the tarball URL and required default extensions

2. Update `Rakefile`:
   - Add the new version to `BUILD_SOURCES`
   - Add a new entry in `NPM_PACKAGES` for the new version

3. Create a new npm package:
   ```console
   # Copy from head package
   $ cp -r packages/npm-packages/ruby-head-wasm-wasi packages/npm-packages/ruby-NEW.VERSION-wasm-wasi

   # Update version references
   # - In package.json: Update name, version, and description
   # - In README.md: Update version references
   ```
   Note: Most of the package contents can be reused from the head package as is, since the JavaScript API and build configuration remain the same across versions.

4. Update `package-lock.json` by `npm install`

4. Update documentation:
   - Update version references in `README.md`
   - Update examples in `docs/cheat_sheet.md`
   - Update the package list in `packages/npm-packages/ruby-wasm-wasi/README.md`

5. Test the build:
   ```console
   $ rake build:NEW.VERSION-wasm32-unknown-wasip1-full
   $ rake npm:ruby-NEW.VERSION-wasm-wasi:build
   $ rake npm:ruby-NEW.VERSION-wasm-wasi:check
   ```

6. Create a pull request with all the changes
