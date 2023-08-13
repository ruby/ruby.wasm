export default function deriveEvalStyle(tag: Element): "async" | "sync" {
  const rawEvalStyle = tag.getAttribute("data-eval") || "sync";
  if (rawEvalStyle !== "async" && rawEvalStyle !== "sync") {
    console.warn(
      `data-eval attribute of script tag must be "async" or "sync". ${rawEvalStyle} is ignored and "sync" is used instead.`,
    );
    return "sync";
  }
  return rawEvalStyle;
}
