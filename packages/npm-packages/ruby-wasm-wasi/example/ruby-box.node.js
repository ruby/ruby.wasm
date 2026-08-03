import fs from "fs/promises";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

// $ node ruby-box.node.js

const main = async () => {
  const binary = await fs.readFile(
    "./node_modules/@ruby/head-wasm-wasi/dist/ruby.wasm",
  );
  const module = await WebAssembly.compile(binary);
  const { vm } = await DefaultRubyVM(module, {
    env: {
      RUBY_BOX: "1",
    },
  });

  vm.eval(`
    box = Ruby::Box.new
    box.eval <<~RUBY
      X = 123
    RUBY

    puts "Ruby::Box.enabled?: #{Ruby::Box.enabled?}"
    puts "box::X: #{box::X}"
  `);
};

main();
