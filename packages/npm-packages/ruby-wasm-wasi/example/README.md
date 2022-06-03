# Example for ruby-wasm-wasi

This is a simple example of how to use the `ruby-wasm-wasi` family packages

## For browser

```console
$ ruby -run -e httpd . -p 8000
$ # Open http://localhost:8000/index.html
```

## For Node.js

```console
$ npm install
$ node --experimental-wasi-unstable-preview1 index.node.js
```
