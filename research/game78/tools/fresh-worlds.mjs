import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { resolve, join } from "node:path";
import { loadWorld, context, eligible } from "../src/context.mjs";
import { sha, canonical } from "../../game77/src/core.mjs";
import { generate, project, validateRecord } from "../src/framework.mjs";
import { render } from "../src/text.mjs";
const helper = resolve(process.env.GAME76_HELPER_ROOT ?? "worldgen-helper"),
  root = resolve(process.env.GAME78_WORLD_DIR ?? "/tmp/game78-fresh-worlds");
mkdirSync(root, { recursive: true });
const binary = join(helper, process.platform === "win32" ? "node.exe" : "node"),
  runtime = JSON.parse(readFileSync(join(helper, "runtime.json")));
if (sha(readFileSync(binary)) !== runtime.runtimeSha256)
  throw Error("Runtime pin mismatch");
const evidence = [];
for (let n = 0; n < 5; n++) {
  const seed = "game78-deep-" + String(n).padStart(2, "0"),
    path = join(root, seed + ".json");
  const t = performance.now();
  execFileSync(
    binary,
    [
      join(helper, "tools/worldgen/helper-entry.mjs"),
      "--seed",
      seed,
      "--output",
      path,
    ],
    {
      env: { ...process.env, PATH: "", NODE_PATH: "", NODE_OPTIONS: "" },
      timeout: 120000,
      stdio: "pipe",
    },
  );
  const first = sha(readFileSync(path));
  const repeat = join(root, seed + "-replay.json");
  execFileSync(
    binary,
    [
      join(helper, "tools/worldgen/helper-entry.mjs"),
      "--seed",
      seed,
      "--output",
      repeat,
    ],
    {
      env: { ...process.env, PATH: "", NODE_PATH: "", NODE_OPTIONS: "" },
      timeout: 120000,
      stdio: "pipe",
    },
  );
  if (sha(readFileSync(repeat)) !== first) throw Error("World replay failed");
  const w = loadWorld(path),
    towns = w.source.settlements.filter(eligible);
  const contrast = [];
  for (const tag of ["port", "walls", "forest", "arid", "wetland", "river"]) {
    const b = towns.find((b) => {
      const c = context(w, "settlements", b.i);
      return tag === "port"
        ? c.port.value > 0
        : tag === "walls"
          ? c.walls.value === true
          : tag === "river"
            ? c.river_id.value > 0
            : new RegExp(
                tag === "forest"
                  ? "forest|woodland|taiga"
                  : tag === "arid"
                    ? "desert"
                    : "wetland|swamp|marsh",
                "i",
              ).test(c.biome.value ?? "");
    });
    if (b && !contrast.some((x) => x.i === b.i)) contrast.push(b);
  }
  for (const b of towns.slice(0, 3))
    if (!contrast.some((x) => x.i === b.i)) contrast.push(b);
  const rows = [];
  for (const b of contrast) {
    const c = context(w, "settlements", b.i);
    for (const d of [
      "origin",
      "character",
      "npc",
      "mundane",
      "rare",
      "contract",
      "group",
    ]) {
      const r = generate(c, d, "fresh", { playthrough_id: "fresh-qa" });
      validateRecord(r, c);
      const p = project(r, { world_id: w.base.id, playthrough_id: "fresh-qa" });
      rows.push({ context: c, record: r, render: render(p) });
    }
  }
  const markers = w.source.markers
    .filter((m) => m && m.type === "ruins" && !m.hidden && !m.removed)
    .slice(0, 3);
  for (const m of markers) {
    const c = context(w, "markers", m.i),
      r = generate(c, "site", "fresh");
    rows.push({
      context: c,
      record: r,
      render: render(
        project(r, { world_id: w.base.id, known_entities: [r.id] }),
      ),
    });
  }
  if (sha(readFileSync(path)) !== first) throw Error("Base mutated");
  evidence.push({
    seed,
    world_id: w.base.id,
    sha256: first,
    replay_equal: true,
    eligible_towns: towns.length,
    contrast_towns: contrast.map((b) => ({
      id: b.i,
      cell: b.cell,
      name: b.name,
    })),
    ruin_markers: markers.map((m) => m.i),
    milliseconds_including_two_generations: performance.now() - t,
    examples: rows,
  });
  console.log("Fresh world verified", seed, rows.length);
}
writeFileSync(
  "research/game78/evidence/fresh-worlds.json",
  JSON.stringify(evidence, null, 2) + "\n",
);
