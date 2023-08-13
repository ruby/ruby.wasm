import loadScriptAsync from "./loadScriptAsync";

export default async function runRubyScriptsInHtml(vm) {
  const tags = document.querySelectorAll('script[type="text/ruby"]');

  // Get Ruby scripts in parallel.
  const promisingRubyScripts = Array.from(tags).map((tag) =>
    loadScriptAsync(tag),
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
}
