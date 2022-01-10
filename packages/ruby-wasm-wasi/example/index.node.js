import { WASI } from "wasi";
import fs from "fs/promises";
import { RubyVM } from "ruby-wasm-wasi";

// $ node --experimental-wasi-unstable-preview1 index.node.js

const main = async () => {
  const wasi = new WASI();
  const binary = await fs.readFile(
    "./node_modules/ruby-wasm-wasi/bin/ruby.wasm"
  );
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const { instance } = await WebAssembly.instantiate(binary.buffer, imports);
  await vm.setInstance(instance);
  // Start WASI application
  wasi.initialize(instance);
  vm.initialize();
  vm.guest.rubyShowVersion();

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
