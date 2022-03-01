# Example for ruby-wasm-emscripten

This is a simple example of how to use the `ruby-wasm-emscripten` package

## How to build

```console
$ npm install
$ npm run build
```

## For browser

```console
$ ruby -run -e httpd . -p 8000
$ # Open http://localhost:8000/index.html
```

## For Node.js

```console
$ node dist/index.js
```
