/** Source facts only; Town Forge styling is not authoritative geography. */
export function sourceContext(world, burgId) {
  if (world.schemaVersion !== 1 || world.generator?.provider !== "azgaar" || world.generator.version !== "1.153.1")
    throw Error("Unsupported Azgaar fixture/generator");
  if (typeof world.seed !== "string" || !world.seed.length) throw Error("Missing world seed");
  if (!Number.isSafeInteger(burgId) || burgId <= 0) throw Error("Invalid burg ID");
  const cells = world.cells;
  if (!Array.isArray(cells?.ids) || !cells.ids.length) throw Error("Missing source cells");
  const index = new Map();
  cells.ids.forEach((id, i) => {
    if (!Number.isSafeInteger(id) || id < 0 || index.has(id)) throw Error("Invalid/duplicate source cell ID");
    index.set(id, i);
  });
  for (const field of ["biome", "heights", "state", "province", "river", "terrain", "points", "neighbors"])
    if (!Array.isArray(cells[field]) || cells[field].length !== cells.ids.length)
      throw Error("Missing/misaligned source cell field: " + field);
  const matches = (world.settlements ?? []).filter(b => b && b.i === burgId);
  if (matches.length !== 1) throw Error("Burg ID missing/duplicated in canonical world");
  const burg = matches[0];
  if (burg.hidden || burg.removed) throw Error("Burg is source-hidden/removed");
  if (!index.has(burg.cell)) throw Error("Burg source cell not in canonical map");
  const at = index.get(burg.cell);
  const cell = {i: burg.cell};
  for (const [target, field] of Object.entries({biome:"biome", height:"heights", state:"state", province:"province", river:"river", terrain:"terrain"})) {
    const value = cells[field][at];
    if (!Number.isFinite(value)) throw Error("Invalid source cell field: " + field);
    cell[target] = value;
  }
  if (cell.height < 20 || cell.height > 100) throw Error("Burg source cell is not valid land");
  if (!Number.isInteger(cell.biome) || cell.biome < 1 || cell.biome > 12) throw Error("Invalid land biome");
  const point = cells.points[at];
  const validPoint = p => Array.isArray(p) && p.length === 2 && p.every(Number.isFinite);
  if (!validPoint(point) || !Array.isArray(cells.neighbors[at])) throw Error("Invalid source cell geometry");
  const wet = cells.neighbors[at].map(id => {
    if (!index.has(id)) throw Error("Unknown neighbouring cell ID");
    const i = index.get(id);
    if (!Number.isFinite(cells.heights[i]) || !validPoint(cells.points[i])) throw Error("Invalid neighbouring cell geometry");
    return {id, i};
  }).filter(n => cells.heights[n.i] < 20).sort((a,b) => a.id-b.id);
  // Azgaar cells.t === 1 is a land shoreline, including lakes. The canonical
  // export lacks pack.features records, so do not infer ocean versus lake.
  let dx = 0, dy = 0;
  for (const n of wet) {
    const p = cells.points[n.i], length = Math.hypot(p[0]-point[0], p[1]-point[1]);
    if (length) { dx += (p[0]-point[0])/length; dy += (p[1]-point[1])/length; }
  }
  const waterSide = cell.terrain === 1 && Math.hypot(dx,dy) > 1e-8
    ? Math.abs(dx) > Math.abs(dy) ? dx > 0 ? "E" : "W" : dy > 0 ? "S" : "N" : null;
  const terrain = cell.terrain === 1 ? "coastal" : cell.river > 0 ? "river" : cell.height >= 68 ? "mountain" : "inland";
  return {burg, cell, terrain, waterSide, wetNeighborIds:wet.map(n=>n.id),
    forestMul: [5,6,7,8,9].includes(cell.biome) ? 1.8 : [1,2,10,11].includes(cell.biome) ? 0.25 : 1};
}

export function geometryPoints(items) {
  if (items == null) return [];
  if (!Array.isArray(items)) throw Error("Town Forge returned invalid geometry array");
  return items.map(p => {
    if (!p || !Number.isFinite(p.x) || !Number.isFinite(p.y)) throw Error("Town Forge returned nonfinite geometry");
    return [Math.round(p.x*1000)/1000, Math.round(p.y*1000)/1000];
  });
}
