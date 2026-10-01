const RELIEF_ID = /^relief-(?:mount|mountSnow|hill)-\d+-illustrated$/;

const escapeAttribute = value =>
  String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");

function symbolGeometry(symbol) {
  const viewBox = (symbol.getAttribute("viewBox") || "0 0 40 40")
    .trim()
    .split(/\s+/)
    .map(Number);
  if (viewBox.length !== 4 || viewBox.some(value => !Number.isFinite(value)) || viewBox[2] <= 0 || viewBox[3] <= 0) {
    throw new Error(`Invalid Azgaar relief symbol viewBox: ${symbol.id}`);
  }
  return {viewBox, inner: symbol.innerHTML.trim()};
}

/**
 * Build a presentation-only SVG from Azgaar's illustrated relief and vegetation assets.
 *
 * The source renderer uses <symbol>/<use>. Godot's ThorVG-based SVG loader has
 * incomplete support for that indirection, so the sidecar expands each placed
 * symbol into direct Azgaar path geometry while preserving the provider's
 * generated order, position, size and artwork.
 */
export function buildReliefSidecar({width, height, relief, sourceDocument}) {
  const icons = relief.filter(({icon}) => RELIEF_ID.test(icon));
  const geometry = new Map();

  const placed = icons.map(({icon, x, y, s}) => {
    let asset = geometry.get(icon);
    if (!asset) {
      const symbol = sourceDocument.getElementById(icon);
      if (!symbol) throw new Error(`Azgaar relief symbol is missing: ${icon}`);
      asset = symbolGeometry(symbol);
      geometry.set(icon, asset);
    }

    const [minX, minY, viewWidth, viewHeight] = asset.viewBox;
    const scaleX = Number(s) / viewWidth;
    const scaleY = Number(s) / viewHeight;
    const transform = [
      `translate(${Number(x)} ${Number(y)})`,
      `scale(${scaleX} ${scaleY})`,
      `translate(${-minX} ${-minY})`
    ].join(" ");

    return [
      `<g data-icon="${escapeAttribute(icon)}" transform="${transform}">`,
      asset.inner,
      "</g>"
    ].join("\n");
  });

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    '<g id="terrain">', ...placed, "</g>",
    "</svg>", ""
  ].join("\n");
}

export function defaultReliefPath(worldPath) {
  return worldPath.replace(/\.json$/i, "") + ".relief.svg";
}
