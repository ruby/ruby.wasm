# Example for ruby-wasm-wasi

This is a simple example of how to use the `ruby-wasm-wasi` family packages

## For browser

```console
$ ruby -run -e httpd . -p 8000
$ # Open http://localhost:8000/hello.html
$ # Open http://localhost:8000/lucky.html
$ # Open http://localhost:8000/script-src
```

## For Node.js

```console
$ npm install
$ node --experimental-wasi-unstable-preview1 index.node.js
```
