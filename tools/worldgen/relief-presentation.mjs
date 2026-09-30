/** Provider-neutral projection of Azgaar's generated relief presentation. */

const round = value => Math.round(value * 100) / 100;

export function projectReliefIcons(icons) {
  return icons
    .map(icon => {
      const match = /^relief-(\w+?)-(\d+)/.exec(icon.icon ?? "");
      if (!match) return null;
      const size = Number(icon.s);
      return {
        kind: match[1],
        variant: Number(match[2]),
        x: round(Number(icon.x) + size / 2),
        y: round(Number(icon.y) + size / 2),
        size: round(size)
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.y + a.size / 2 - (b.y + b.size / 2) || a.x - b.x);
}

// A tiny local PRNG means hachures don't consume or depend on Azgaar's global
// random stream. The exported strokes are presentation data, not cell geometry.
function randomFor(seed, cellId) {
  let state = 2166136261;
  for (const character of `${seed}:${cellId}`) {
    state ^= character.charCodeAt(0);
    state = Math.imul(state, 16777619);
  }
  return () => {
    state += 0x6d2b79f5;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

export function generateSlopeHachures({seed, points, heights, neighbors}) {
  const strokes = [];
  for (let cellId = 0; cellId < points.length; cellId++) {
    const height = Number(heights[cellId] ?? 0);
    if (height < 38) continue;
    const point = points[cellId];
    if (!Array.isArray(point) || point.length < 2) continue;

    const random = randomFor(seed, cellId);
    const density = Math.min(0.82, 0.18 + (height - 38) / 75);
    if (random() > density) continue;

    let gradientX = 0;
    let gradientY = 0;
    for (const neighborId of neighbors[cellId] ?? []) {
      const neighbor = points[neighborId];
      if (!Array.isArray(neighbor) || neighbor.length < 2) continue;
      const drop = Math.max(0, height - Number(heights[neighborId] ?? height));
      const dx = Number(neighbor[0]) - Number(point[0]);
      const dy = Number(neighbor[1]) - Number(point[1]);
      const distance = Math.hypot(dx, dy) || 1;
      gradientX += dx / distance * drop;
      gradientY += dy / distance * drop;
    }
    if (Math.hypot(gradientX, gradientY) < 0.01) {
      const angle = random() * Math.PI * 2;
      gradientX = Math.cos(angle);
      gradientY = Math.sin(angle);
    }
    const gradientLength = Math.hypot(gradientX, gradientY);
    const length = 2.4 + Math.min(4.2, (height - 38) * 0.075) + random() * 1.2;
    const jitter = 2.25;
    strokes.push({
      x: round(Number(point[0]) + (random() - 0.5) * jitter),
      y: round(Number(point[1]) + (random() - 0.5) * jitter),
      dx: round(gradientX / gradientLength * length),
      dy: round(gradientY / gradientLength * length),
      strength: round(Math.min(1, 0.3 + (height - 38) / 62))
    });
  }
  return strokes;
}
