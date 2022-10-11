import { DefaultRubyVM } from "./browser";

export const main = async (pkg: { name: string; version: string }) => {
  const response = await fetch(
    `https://cdn.jsdelivr.net/npm/${pkg.name}@${pkg.version}/dist/ruby+stdlib.wasm`
  );
  const buffer = await response.arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const { vm } = await DefaultRubyVM(module);

  vm.printVersion();

  globalThis.rubyVM = vm;

  // Wait for the text/ruby script tag to be read.
  // It may take some time to read ruby+stdlib.wasm
  // and DOMContentLoaded has already been fired.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () =>
      runRubyScriptsInHtml(vm)
    );
  } else {
    runRubyScriptsInHtml(vm);
  }
};

const runRubyScriptsInHtml = async (vm) => {
  const tags = document.querySelectorAll('script[type="text/ruby"]');

  // Get Ruby scripts in parallel.
  const promisingRubyScripts = Array.from(tags).map((tag) =>
    loadScriptAsync(tag)
  );

  // Run Ruby scripts sequentially.
  for await (const rubyScript of promisingRubyScripts) {
    if (rubyScript) {
      vm.eval(rubyScript);
    }
  }
};

const loadScriptAsync = async (tag: Element): Promise<string> => {
  // Inline comments can be written with the src attribute of the script tag.
  // The presence of the src attribute is checked before the presence of the inline.
  // see: https://html.spec.whatwg.org/multipage/scripting.html#inline-documentation-for-external-scripts
  if (tag.hasAttribute("src")) {
    const url = encodeURI(tag.getAttribute("src"));
    const response = await fetch(url);

    if (response.ok) {
      return await response.text();
    }

    return Promise.resolve(null);
  }

  return Promise.resolve(tag.innerHTML);
};
