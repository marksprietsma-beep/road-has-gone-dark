import { loadWorld, context } from "../src/context.mjs";
import { generate, project, domains } from "../src/framework.mjs";
import { render } from "../src/text.mjs";
const w = loadWorld("tests/worldgen/fixtures/game-11-determinism.json");
for (const d of domains) {
  const c = context(
    w,
    d === "site" ? "markers" : "settlements",
    d === "site" ? 51 : 771,
  );
  const r = generate(c, d, "0", { playthrough_id: "qa-78" });
  const p = project(r, {
    world_id: w.base.id,
    playthrough_id: "qa-78",
    known_entities: [r.id],
  });
  console.log(d, render(p, { extended: true }).text);
}
