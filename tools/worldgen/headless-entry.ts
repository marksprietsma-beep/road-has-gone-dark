/** Project-owned adapter around the pinned Azgaar generation model. */
import {generateSlopeHachures, projectReliefIcons} from "./relief-presentation.mjs";

export async function generateCanonicalWorld(seed: string) {
  await import("@/test-setup");
  await import("@/utils");
  await import("@/data/supporters");
  await import("@/data/heightmap-templates");
  await import("@/data/precreated-heightmaps");
  await import("@/components/globals");
  await import("@/generators");

  const {setSeed} = await import("@/components/seed");
  const {GenerationPipeline} = await import("@/generators/generation-pipeline");

  globalThis.mapHistory = [];
  globalThis.options = Options.getDefaultOptions();
  setSeed(seed);
  Options.randomize();
  // A source template avoids the optional image/canvas heightmap path.
  options.generation.template = "continents";
  await GenerationPipeline.run({});

  const cells = pack.cells;
  const array = (value: ArrayLike<unknown> | undefined) => Array.from(value ?? []);
  const plain = (value: unknown): unknown => {
    if (value === undefined || typeof value === "function") return null;
    if (typeof value === "number") return Number.isFinite(value) ? value : null;
    if (value === null || typeof value !== "object") return value;
    if (ArrayBuffer.isView(value)) return Array.from(value as ArrayLike<unknown>, plain);
    if (Array.isArray(value)) return value.map(plain);
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter(([, item]) => typeof item !== "function" && item !== undefined)
        .map(([key, item]) => [key, plain(item)])
    );
  };
  const entities = (items: unknown[]) => items.map(plain);
  // Relief is a renderer concern and is intentionally generated after the
  // canonical world pipeline. The headless adapter has no loaded map style,
  // so provide only the upstream generator's presentation options.
  (globalThis as any).styles = {
    relief: {options: {set: "illustrated", size: 0.72, density: 0.3}}
  };
  const relief = Relief.generate();
  const presentation = {
    relief: projectReliefIcons(relief),
    slopeHachures: generateSlopeHachures({
      seed,
      points: cells.p,
      heights: cells.h,
      neighbors: cells.c
    })
  };

  return {
    schemaVersion: 1,
    generator: {provider: "azgaar", version: "1.153.1", upstreamCommit: "cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6"},
    seed,
    presentation,
    map: {
      width: options.map.graph.width,
      height: options.map.graph.height,
      bounds: plain(options.map.geography.coordinates),
      geography: entities(pack.features)
    },
    cells: {
      ids: array(cells.i), points: array(cells.p), neighbors: array(cells.c), heights: array(cells.h),
      features: array(cells.f), terrain: array(cells.t), biome: array(cells.biome), culture: array(cells.culture),
      religion: array(cells.religion), state: array(cells.state), province: array(cells.province),
      settlement: array(cells.burg), river: array(cells.r), population: array(cells.pop), area: array(cells.area)
    },
    states: entities(pack.states),
    provinces: entities(pack.provinces),
    settlements: entities(pack.burgs),
    cultures: entities(pack.cultures),
    religions: entities(pack.religions),
    biomes: entities(pack.biomes),
    rivers: entities(pack.rivers),
    routes: entities(pack.routes),
    markers: entities(pack.markers)
  };
}
