import { loadWorld, context, eligible } from "../src/context.mjs";
import { generate, project, packSha, envelope } from "../src/framework.mjs";
import { render } from "../src/text.mjs";
import { canonical } from "../../game77/src/core.mjs";
import { writeFileSync, statSync, readFileSync } from "node:fs";
const w = loadWorld("tests/worldgen/fixtures/game-11-determinism.json"),
  c = context(w, "settlements", 771);
const metrics = {
  platform: process.platform,
  node: process.version,
  pack_bytes: statSync("research/game78/packs/trhgd-expanded-v1.json").size,
  pack_sha: packSha,
  baseline_memory: process.memoryUsage(),
  trials: [],
};
for (const provider of ["sha-staged", "lexicon-staged"]) {
  let t = performance.now();
  for (let i = 0; i < 10000; i++)
    generate(c, "origin", String(i), { provider });
  metrics.trials.push({
    scope: "origin entity",
    provider,
    entities: 10000,
    total_ms: performance.now() - t,
  });
  t = performance.now();
  let size = 0;
  for (let i = 0; i < 100; i++) {
    const records = [];
    for (const d of ["origin", "npc", "mundane", "rare", "contract", "group"]) {
      const r = generate(c, d, "bench:" + i, { provider });
      records.push(r);
      render(project(r, { world_id: w.base.id }));
    }
    size += canonical(records).length;
  }
  metrics.trials.push({
    scope: "town research bundle (six facts and public descriptions)",
    provider,
    towns: 100,
    total_ms: performance.now() - t,
    serialized_bytes: size,
  });
  t = performance.now();
  const towns = w.source.settlements.filter(
    (b) =>
      b && typeof b === "object" && !b.removed && !b.hidden && b.population > 0,
  );
  const records = towns.map((b) =>
    generate(context(w, "settlements", b.i), "origin", "world", { provider }),
  );
  const elapsed = performance.now() - t;
  const e = envelope(w.base, records);
  metrics.trials.push({
    scope:
      "whole actual world, one public-origin record per visible populated settlement",
    provider,
    towns: towns.length,
    total_ms: elapsed,
    sidecar_bytes: Buffer.byteLength(canonical(e)),
  });
}
metrics.final_memory = process.memoryUsage();
metrics.limits =
  "Warm in-process research Node24 measurement, not Windows frame time. World trial includes canonical context route lookups and JSON evidence memory is separate from streaming runtime.";
writeFileSync(
  "research/game78/evidence/performance.json",
  JSON.stringify(metrics, null, 2) + "\n",
);
console.log(metrics);
