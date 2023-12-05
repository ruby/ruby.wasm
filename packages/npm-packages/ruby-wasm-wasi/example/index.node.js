import fs from "fs/promises";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

// $ node --experimental-wasi-unstable-preview1 index.node.js

const main = async () => {
  const binary = await fs.readFile(
    "./node_modules/@ruby/head-wasm-wasi/dist/ruby.wasm",
  );
  const module = await WebAssembly.compile(binary);
  const { vm } = await DefaultRubyVM(module);

  vm.printVersion();

  const a = vm.eval(`
  class A
    def foo(arg)
      puts "yay: #{arg}"
    end
  end
  $a = A.new
  `);
  console.log(`${a}`);
  a.call("foo", vm.eval("2"));
  try {
    a.call("bar");
  } catch (error) {
    console.log("caught", error);
  }
  vm.eval("puts 'Hey!'");
  vm.eval("puts 'Hey!'");
  vm.eval("puts 'Hey!'");
  vm.eval("puts $a");
  try {
    vm.eval("raise 'panic!'");
  } catch (error) {
    console.log("caught", error);
  }
  console.log(a.toString());
  vm.eval(`
    require "js"
    puts JS.global
  `);
};

main();
