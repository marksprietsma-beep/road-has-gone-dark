const RELIEF_ID = /^relief-(?:mount|mountSnow|hill)-\d+-illustrated$/;

const escapeAttribute = value =>
  String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");

/** Build a presentation-only SVG using Azgaar's own illustrated symbols and placements. */
export function buildReliefSidecar({width, height, relief, sourceDocument}) {
  const icons = relief.filter(({icon}) => RELIEF_ID.test(icon));
  const ids = [...new Set(icons.map(({icon}) => icon))].sort();
  const symbols = ids.map(id => {
    const symbol = sourceDocument.getElementById(id);
    if (!symbol) throw new Error(`Azgaar relief symbol is missing: ${id}`);
    return symbol.outerHTML;
  });
  const uses = icons.map(({icon, x, y, s}) =>
    `<use href="#${escapeAttribute(icon)}" x="${x}" y="${y}" width="${s}" height="${s}"/>`
  );

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    "<defs>", ...symbols, "</defs>",
    '<g id="terrain">', ...uses, "</g>",
    "</svg>", ""
  ].join("\n");
}

export function defaultReliefPath(worldPath) {
  return worldPath.replace(/\.json$/i, "") + ".relief.svg";
}
