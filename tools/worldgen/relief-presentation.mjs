const RELIEF_ID = /^relief-(\w+?)-(\d+)/;
const MOUNTAIN_KINDS = new Set(["mount", "mountSnow", "hill"]);

/** Convert provider icons into the stable, renderer-facing presentation boundary. */
export function projectRelief(icons) {
  return icons.map(({icon, x, y, s}, index) => {
    const match = String(icon).match(RELIEF_ID);
    return {
      kind: match?.[1] ?? "unknown",
      variant: Number(match?.[2] ?? 1),
      x: Number(x),
      y: Number(y),
      size: Number(s),
      order: index
    };
  });
}

/**
 * Build a provider-neutral ridge underlay from placed mountain symbols.
 * Coordinates are deliberately derived from presentation icons, not cells, so
 * no Voronoi geometry crosses the canonical export boundary.
 */
export function createSlopeHachures(relief) {
  const strokes = [];
  for (const item of relief) {
    if (!MOUNTAIN_KINDS.has(item.kind)) continue;
    const strength = item.kind === "hill" ? 0.42 : 0.78;
    const count = item.kind === "hill" ? 1 : 3;
    const cx = item.x + item.size * 0.5;
    const bottom = item.y + item.size * 0.86;
    for (let lane = 0; lane < count; lane++) {
      const phase = ((item.variant * 17 + item.order * 13 + lane * 7) % 11 - 5) / 10;
      const spread = item.size * (0.18 + lane * 0.13);
      strokes.push({
        x1: round(cx - spread), y1: round(bottom - item.size * (0.52 - lane * 0.09)),
        x2: round(cx + spread + phase), y2: round(bottom + item.size * (0.08 + lane * 0.035)),
        strength
      });
    }
  }
  return strokes;
}

const round = value => Math.round(value * 100) / 100;
