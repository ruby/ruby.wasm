import deriveEvalStyle from "./deriveEvalStyle";

export default async function loadScriptAsync(
  tag: Element,
): Promise<{ scriptContent: string; evalStyle: "async" | "sync" } | null> {
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
}
