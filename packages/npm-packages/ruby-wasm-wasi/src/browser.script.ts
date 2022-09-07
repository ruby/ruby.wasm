import { DefaultRubyVM } from "./browser";

export const main = async (pkg: { name: string, version: string }) => {
    const response = await fetch(
        `https://cdn.jsdelivr.net/npm/${pkg.name}@${pkg.version}/dist/ruby.wasm`
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
