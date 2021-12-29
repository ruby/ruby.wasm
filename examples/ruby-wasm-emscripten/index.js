import { loadRuby } from "ruby-wasm-emscripten";

const main = async () => {
  const args = ["--disable-gems", "-e", "puts 'Hello :)'"];
  console.log(`$ ruby.wasm ${args.join(" ")}`);
  const defaultModule = {
    locateFile: (path) => "./node_modules/ruby-wasm-emscripten/" + path,
    setStatus: (msg) => console.log(msg),
    print: (line) => {
      if (document) {
        document.body.innerText += line;
      }
      console.log(line);
    },
    arguments: args,
  };
  await loadRuby(defaultModule);
};

main();
