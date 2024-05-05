# @ruby/wasm-emscripten

This package provides WebAssembly port of CRuby by Emscripten with a thin JavaScript wrapper. WebAssembly binaries are distributed in version-specific packages.

> [!WARNING]
> This package is not well-tested yet. Please use [`@ruby/wasm-wasi`](../ruby-wasm-wasi) instead if you don't have a specific reason to use Emscripten.

## Ruby Version Support

| Channel | Package |
| ------- | ------- |
| `head`  | [`ruby-head-wasm-emscripten`](./../ruby-head-wasm-emscripten) |

## Installation

For installing `@ruby/head-wasm-emscripten`, just run this command in your shell:

```console
$ npm install --save @ruby/wasm-emscripten@latest @ruby/head-wasm-emscripten@latest
# or if you want the nightly snapshot
$ npm install --save @ruby/head-wasm-emscripten@next
# or you can specify the exact snapshot version
$ npm install --save @ruby/head-wasm-emscripten@2.6.0-2024-05-05-a
```

## Quick Start

This quick start is for browsers and Node.js environments. See [the example project](https://github.com/ruby/ruby.wasm/tree/main/packages/npm-packages/ruby-wasm-emscripten/example) for more details.

```javascript
import { loadRuby } from "@ruby/head-wasm-emscripten";

const main = async () => {
  const args = ["--disable-gems", "-e", "puts 'Hello :)'"];
  console.log(`$ ruby.wasm ${args.join(" ")}`);

  const defaultModule = {
    locateFile: (path) => "./node_modules/@ruby/head-wasm-emscripten/dist/" + path,
    setStatus: (msg) => console.log(msg),
    print: (line) => console.log(line),
    arguments: args,
  };

  await loadRuby(defaultModule);
};

main();

```

## APIs

`loadRuby(defaultModule): Promise<Module>`

This package provides only `loadRuby` function, which loads the Ruby interpreter and stdlib asynchronously.

This takes a `defaultModule` object as an argument, which is used as a base for the Emscripten's Module object.

### Module object

> Module is a global JavaScript object with attributes that Emscripten-generated code calls at various points in its execution.

https://emscripten.org/docs/api_reference/module.html

This package is a thin wrapper of Emscripten module, so you can control the behavior of the interpreter by modifying the Emscripten's Module object.


## Building the package from source

For building the package from source, you need to prepare a Ruby build produced by Emscripten, and you need Emscripten SDK in your PATH.

The instructions for building a Ruby targeting WebAssembly are available [here](https://github.com/ruby/ruby.wasm#building-from-source).

Then, you can run the following command in your shell:

```console
# Check the directory structure of your Ruby build
$ tree -L 3 path/to/wasm32-unknown-emscripten-full/
path/to/wasm32-unknown-emscripten-full/
├── usr
│   └── local
│       ├── bin
│       ├── include
│       ├── lib
│       └── share
└── var
    └── lib
        └── gems
$ ./build-package.sh path/to/wasm32-unknown-emscripten-full/
Remember to build the main file with  -s FORCE_FILESYSTEM=1  so that it includes support for loading this file package

index.js → dist...
created dist in 3.5s
```

It's recommended to build on a Docker container with the following command:

```console
$ docker run -it --rm \
    -v $(pwd):/src \
    -v path/to/wasm32-unknown-emscripten-full:/install \
    emscripten/emsdk /bin/bash
```
