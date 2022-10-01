import { DefaultRubyVM } from "./browser";

export const main = async (pkg: { name: string, version: string }) => {
    const response = await fetch(
        `https://cdn.jsdelivr.net/npm/${pkg.name}@${pkg.version}/dist/ruby+stdlib.wasm`
    );
    const buffer = await response.arrayBuffer();
    const module = await WebAssembly.compile(buffer);
    const { vm } = await DefaultRubyVM(module);

    vm.printVersion();

    globalThis.rubyVM = vm;

    runRubyScriptsInHtml(vm);
};

const runRubyScriptsInHtml = async (vm) => {
    const tags = document.getElementsByTagName("script");
    for (var i = 0, len = tags.length; i < len; i++) {
        const tag = tags[i];
        if (tag.type === "text/ruby") {
            if (tag.hasAttribute('src')){
                const response = await fetch(
                    tag.getAttribute('src')
                );
                const rubyScript = await response.text();
                vm.eval(rubyScript);
            } else if (tag.innerHTML) {
                vm.eval(tag.innerHTML);
            }
        }
    }
};
