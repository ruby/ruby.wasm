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
  for await (const script of promisingRubyScripts) {
    if (script) {
      const { scriptContent, evalStyle } = script;
      switch (evalStyle) {
        case "async":
          vm.evalAsync(scriptContent);
          break;
        case "sync":
          vm.eval(scriptContent);
          break;
      }
    }
  }
};

const deriveEvalStyle = (tag: Element): "async" | "sync" => {
  const rawEvalStyle = tag.getAttribute("data-eval") || "sync";
  if (rawEvalStyle !== "async" && rawEvalStyle !== "sync") {
    console.warn(`data-eval attribute of script tag must be "async" or "sync". ${rawEvalStyle} is ignored and "sync" is used instead.`);
    return "sync";
  }
  return rawEvalStyle;
};

const loadScriptAsync = async (tag: Element): Promise<{ scriptContent: string, evalStyle: "async" | "sync" } | null> => {
  const evalStyle = deriveEvalStyle(tag);
  // Inline comments can be written with the src attribute of the script tag.
  // The presence of the src attribute is checked before the presence of the inline.
  // see: https://html.spec.whatwg.org/multipage/scripting.html#inline-documentation-for-external-scripts
  if (tag.hasAttribute("src")) {
    const url = tag.getAttribute("src");
    const response = await fetch(url);

    if (response.ok) {
      return { scriptContent: await response.text(), evalStyle };
    }

    return Promise.resolve(null);
  }

  return Promise.resolve({ scriptContent: tag.innerHTML, evalStyle });
};
