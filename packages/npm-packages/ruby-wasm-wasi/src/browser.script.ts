import { DefaultRubyVM } from "./browser";
import * as pkg from "../package.json";

const main = async () => {
    const response = await fetch(
        `https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@${pkg.version}/dist/ruby.wasm`
    );
    const buffer = await response.arrayBuffer();
    const module = await WebAssembly.compile(buffer);
    const { vm } = await DefaultRubyVM(module);

    vm.printVersion();

    runRubyScriptsInHtml(vm);
};

const runRubyScriptsInHtml = (vm) => {
    const tags = document.getElementsByTagName("script");
    for (var i = 0, len = tags.length; i < len; i++) {
        const tag = tags[i];
        if (tag.type === "text/ruby") {
            if (tag.innerHTML) {
                vm.eval(tag.innerHTML);
            }
        }
    }
};

main();
