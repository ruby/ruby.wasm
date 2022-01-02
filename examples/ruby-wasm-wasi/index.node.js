import { WASI } from "wasi"
import fs from "fs/promises";
import { RubyVM } from "ruby-wasm-wasi";

// $ node --experimental-wasi-unstable-preview1 index.node.js

const main = async () => {
  const wasi = new WASI();
  const binary = await fs.readFile("./node_modules/ruby-wasm-wasi/bin/ruby.wasm");
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const { instance } = await WebAssembly.instantiate(binary.buffer, imports);
  await vm.init(instance);
  // Start WASI application
  wasi.initialize(instance);
  vm.guest.rubyInit();
  // const args = ["ruby.wasm\0", "--version\0"];
  const args = ["ruby.wasm\0", "-e\0", "_=0\0"];
  // vm.guest.rubySysinit(args);
  vm.guest.rubyOptions(args)
  // /vm.guest.rubyShowVersion();
  // /vm.guest.rubyInit();
  // /const a = vm.eval(`
  // /class A
  // /  def foo(arg)
  // /    puts "yay: #{arg}"
  // /  end
  // /end
  // /A.new
  // /`)
  // /// console.log(`${a}`)
  // /a.bar()
  // /vm.eval("puts 'Hey!'");
  // /vm.eval("puts 'Hey!'");
  // /vm.eval("puts 'Hey!'");
  // /// vm.eval("puts $a");
  // /console.log(a.toString())
  // console.log(a.toString())
  // vm.eval("raise 'panic!'")
};

main()
