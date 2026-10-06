// Research extension of the unchanged GAME-77/GameWorld boundary. No new world
// schema: these views retain exact original IDs and explicit source provenance.
import {
  loadWorld as loadBase,
  context as baseContext,
  eligible,
} from "../../game77/src/context.mjs";
export { eligible };
export const loadWorld = loadBase;
const indexes = new WeakMap();
function index(world) {
  if (indexes.has(world)) return indexes.get(world);
  const towns = world.source.settlements.filter(
      (b) =>
        b &&
        typeof b === "object" &&
        !b.hidden &&
        !b.removed &&
        b.population > 0,
    ),
    byCell = new Map();
  for (const b of towns) {
    const values = byCell.get(b.cell) ?? [];
    values.push(b);
    byCell.set(b.cell, values);
  }
  const populations = towns.map((b) => b.population).sort((a, b) => a - b);
  const result = {
    byCell,
    median: populations[Math.floor(populations.length / 2)] ?? null,
  };
  indexes.set(world, result);
  return result;
}
export function context(world, kind, id) {
  const ctx = baseContext(world, kind, id),
    entity = world.record(kind, id),
    cell = world.cell(entity.cell),
    data = index(world);
  const fact = (value, path, status = "source-exact") => ({
    value: value ?? null,
    status: value == null ? "unknown" : status,
    provenance: path,
  });
  ctx.settlement_class = fact(
    kind === "settlements" ? (entity.group ?? null) : null,
    `${kind}:${id}.group`,
  );
  ctx.capital = fact(
    kind === "settlements" && Object.hasOwn(entity, "capital")
      ? Boolean(entity.capital)
      : null,
    `${kind}:${id}.capital`,
  );
  ctx.population = fact(
    kind === "settlements" ? (entity.population ?? null) : null,
    `${kind}:${id}.population (uncalibrated source-relative)`,
  );
  ctx.relative_importance = fact(
    kind === "settlements" && data.median != null
      ? entity.population > data.median
        ? "above-world-median"
        : "at-or-below-world-median"
      : null,
    "comparison with visible positive source burg populations; no physical conversion",
    "source-derived",
  );
  const sourceCells = new Set([entity.cell, ...(cell.neighbors ?? [])]);
  ctx.adjacent_settlements = fact(
    [...sourceCells]
      .flatMap((cellId) =>
        (data.byCell.get(cellId) ?? [])
          .filter((b) => kind !== "settlements" || b.i !== id)
          .map((b) => ({
            burg_id: b.i,
            cell_id: b.cell,
            name: b.name,
            world_id: world.base.id,
            relationship:
              cellId === entity.cell
                ? "same-source-cell"
                : "adjacent-source-cell",
          })),
      )
      .sort((a, b) => a.burg_id - b.burg_id),
    "actual source cells.neighbors and public original burg membership; not inferred road connectivity",
    "source-derived",
  );
  return ctx;
}
