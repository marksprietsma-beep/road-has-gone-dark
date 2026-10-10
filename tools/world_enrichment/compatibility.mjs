// Original declarative compatibility engine. No vendor prose/trait tables.
export const normal = (s) =>
  String(s)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
export function satisfies(rule, tags) {
  if (rule === undefined) return true;
  if (typeof rule === "string") return tags.has(rule);
  if (Array.isArray(rule)) return rule.every((r) => satisfies(r, tags));
  if (rule && Object.keys(rule).length === 1) {
    if (rule.all) return rule.all.every((r) => satisfies(r, tags));
    if (rule.any) return rule.any.some((r) => satisfies(r, tags));
    if (rule.not) return !satisfies(rule.not, tags);
  }
  throw Error("Invalid prerequisite rule");
}
export function compatible(row, tags, selected = []) {
  if (!satisfies(row.requires, tags)) return false;
  const ids = new Set(selected.map((r) => r.id));
  if (
    (row.conflicts ?? []).some((x) => ids.has(normal(x)) || tags.has(normal(x)))
  )
    return false;
  return !selected.some((r) =>
    (r.conflicts ?? []).map(normal).includes(row.id),
  );
}
export function choose(seed, field, rows, tags, selected = [], picker = null) {
  const candidates = rows.filter(
    (r) =>
      compatible(r, tags, selected) && !selected.some((x) => x.id === r.id),
  );
  if (!candidates.length) throw Error("No compatible candidates: " + field);
  const row = picker ? picker(field, candidates) : seed.pick(field, candidates);
  return structuredClone(row);
}
export function validateSelection(rows, tags) {
  for (let i = 0; i < rows.length; i++)
    if (
      !compatible(
        rows[i],
        tags,
        rows.filter((_, j) => j !== i),
      )
    )
      throw Error("Contradiction: " + rows[i].id);
  return true;
}
export function contextTags(ctx) {
  const tags = new Set();
  if (ctx.port?.value > 0) tags.add("port");
  if (ctx.walls?.value === true) tags.add("walls");
  if (ctx.river_id?.value > 0) tags.add("river");
  if (ctx.religion?.value) tags.add("religion");
  if (ctx.culture?.value) tags.add("culture");
  const biome = ctx.biome?.value ?? "";
  if (/forest|woodland|taiga/i.test(biome)) tags.add("forest");
  if (/desert/i.test(biome)) tags.add("arid");
  if (/wetland|swamp|marsh/i.test(biome)) tags.add("wetland");
  if (ctx.capital?.value === true) tags.add("capital");
  if (ctx.settlement_class?.value)
    tags.add("settlement:" + ctx.settlement_class.value);
  if (ctx.relative_importance?.value === "above-world-median")
    tags.add("larger-relative");
  if (ctx.adjacent_settlements?.value?.length) tags.add("adjacent-town");
  if (ctx.road_ids?.value?.length) tags.add("road-cell");
  if (ctx.trail_ids?.value?.length) tags.add("trail-cell");
  return tags;
}
// Relationship prerequisites are explicit: a migration can explain an inland
// sailor, but it does not turn the birthplace into a port.
export const regressionRules = {
  harbour: {
    id: "harbour-worker",
    requires: { any: ["port", "navigable-water"] },
  },
  sailor: {
    id: "lifelong-sailor",
    requires: { any: ["port", "migration-from-port"] },
  },
  orphanInheritance: {
    id: "father-workshop",
    requires: { any: ["living-father", "guardian-inheritance"] },
  },
  priest: { id: "devout-priest", requires: ["religion"] },
  soldier: {
    id: "former-soldier",
    requires: { any: ["source-military", "migration-from-campaign"] },
  },
};
