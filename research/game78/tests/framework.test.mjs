import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadWorld, context, eligible } from "../src/context.mjs";
import { canonical, sha, ContentSeed } from "../../game77/src/core.mjs";
import {
  generate,
  project,
  envelope,
  verifySidecar,
  writeSidecar,
  validateRecord,
  pack,
  packSha,
  domains,
} from "../src/framework.mjs";
import { render, originPayload } from "../src/text.mjs";
import {
  satisfies,
  compatible,
  validateSelection,
  regressionRules,
  contextTags,
} from "../src/compatibility.mjs";
const worlds = ["game-11-determinism", "atlas-showcase"].map((name) =>
    loadWorld("tests/worldgen/fixtures/" + name + ".json"),
  ),
  w = worlds[0],
  c = context(w, "settlements", 771),
  s = context(w, "markers", 51);
const options = { playthrough_id: "test78" },
  knowledge = (r) => ({
    world_id: r.source.world_id,
    playthrough_id: "test78",
    known_entities: [r.id],
  });
test("domain/provider replay, order independence, sibling addition and display-name independence", () => {
  for (const provider of ["sha-staged", "lexicon-staged"])
    for (const d of domains) {
      const ctx = d === "site" ? s : c,
        opts = { ...options, provider },
        a = generate(ctx, d, "17", opts);
      generate(ctx, d, "18", opts);
      for (const other of domains)
        generate(other === "site" ? s : c, other, "21", opts);
      assert.equal(canonical(a), canonical(generate(ctx, d, "17", opts)));
      assert.equal(
        render(project(a, knowledge(a))).text,
        render(project(a, knowledge(a))).text,
      );
      const renamed = structuredClone(ctx);
      renamed.display_name = "Renamed for diagnostics";
      const b = generate(renamed, d, "17", opts);
      assert.equal(a.seed, b.seed);
      assert.deepEqual(a.source, b.source);
      if (d === "site") delete a.public.source_name;
      else if (d === "origin") delete a.public.hometown;
      else if (["character", "npc"].includes(d))
        delete a.public.birthplace.name;
      const bp = structuredClone(b.public);
      if (d === "site") delete bp.source_name;
      else if (d === "origin") delete bp.hometown;
      else if (["character", "npc"].includes(d)) delete bp.birthplace.name;
      assert.deepEqual(a.public, bp);
      assert.notEqual(a.seed, generate(ctx, d, "18", opts).seed);
    }
  assert.throws(() => generate(c, "character"), /playthrough/);
  assert.throws(() => generate(c, "site"), /markers/);
  assert.throws(() => generate(s, "origin"), /hometown/);
});
test("declarative prerequisites, both conflict directions and explicit relationship resolution", () => {
  const empty = new Set();
  assert.equal(compatible(regressionRules.harbour, empty), false);
  assert.equal(compatible(regressionRules.harbour, new Set(["river"])), false);
  assert.equal(compatible(regressionRules.harbour, new Set(["port"])), true);
  assert.equal(compatible(regressionRules.sailor, empty), false);
  assert.equal(
    compatible(regressionRules.sailor, new Set(["migration-from-port"])),
    true,
  );
  assert.equal(
    compatible(regressionRules.orphanInheritance, new Set(["orphan"])),
    false,
  );
  assert.equal(
    compatible(
      regressionRules.orphanInheritance,
      new Set(["orphan", "guardian-inheritance"]),
    ),
    true,
  );
  assert.equal(compatible(regressionRules.priest, empty), false);
  assert.equal(compatible(regressionRules.soldier, new Set(["walls"])), false);
  assert.equal(
    compatible(regressionRules.soldier, new Set(["migration-from-campaign"])),
    true,
  );
  for (const ids of [
    ["cowardly", "fearless"],
    ["reckless", "cowardly"],
    ["patient", "impatient"],
    ["private", "boastful"],
  ])
    assert.throws(
      () =>
        validateSelection(
          ids.map((id) => pack.traits.find((x) => x.id === id)),
          empty,
        ),
      /Contradiction/,
    );
  assert.throws(() => satisfies({ unknown: [] }, empty), /Invalid/);
});
test("all actual eligible hometowns in both fixtures preserve geography and hidden boundaries", () => {
  let count = 0;
  const hashes = worlds.map((x) => x.base.sha256);
  for (const world of worlds)
    for (const town of world.source.settlements.filter(eligible)) {
      const ctx = context(world, "settlements", town.i);
      for (let n = 0; n < 2; n++)
        for (const d of [
          "origin",
          "character",
          "npc",
          "mundane",
          "rare",
          "contract",
          "group",
        ]) {
          const r = generate(ctx, d, "context:" + n, options);
          assert.equal(validateRecord(r, ctx), true);
          assert.equal(r.source.cell_id, town.cell);
          assert.equal(r.source.world_id, world.base.id);
          assert.equal(r.context.port.value, ctx.port.value);
          if (!(ctx.port.value > 0) && r.public.occupation)
            assert.ok(
              !["harbour-worker", "net-maker"].includes(r.public.occupation),
            );
          const txt = render(project(r, knowledge(r))).text;
          assert.ok(
            !/ocean|coastal|navigable|guild protection|safe haven|danger level|https:/i.test(
              txt,
            ),
          );
          count++;
        }
    }
  for (let i = 0; i < worlds.length; i++)
    assert.equal(
      sha(
        readFileSync(
          "tests/worldgen/fixtures/" +
            ["game-11-determinism", "atlas-showcase"][i] +
            ".json",
        ),
      ),
      hashes[i],
    );
  console.log("Validated source-context records:", count);
  const h = loadWorld("tests/worldgen/fixtures/game-11-determinism.json");
  const original = h.source.settlements.find((x) => x.i === 771);
  original.hidden = true;
  assert.throws(() => context(h, "settlements", 771), /Unavailable/);
  original.hidden = false;
  original.removed = true;
  assert.throws(() => context(h, "settlements", 771), /Unavailable/);
});
test("visibility rejects secrets, rumours verdicts, unknown sites and cross-world keys", () => {
  for (const d of domains) {
    const r = generate(d === "site" ? s : c, d, "visibility", options);
    r.secret = { sentinel: "GAME78_HIDDEN_TRUTH" };
    r.provenance.sentinel = "DEVELOPER_ONLY";
    assert.equal(
      project(r, { ...knowledge(r), world_id: worlds[1].base.id }),
      null,
    );
    const p = project(r, knowledge(r));
    const data = canonical(p);
    assert.ok(!data.includes("GAME78_HIDDEN_TRUTH"));
    assert.ok(!data.includes("DEVELOPER_ONLY"));
    assert.ok(!data.includes("truth"));
    assert.throws(() => render(r), /public projection/);
    if (d === "site")
      assert.equal(
        project(r, { world_id: w.base.id, known_entities: [] }),
        null,
      );
    if (d === "character")
      assert.equal(
        project(r, { world_id: w.base.id, playthrough_id: "other" }),
        null,
      );
    const heard = project(r, {
      ...knowledge(r),
      heard_rumours: r.rumours.map((x) => r.id + ":" + x.id),
    });
    for (const rumour of heard.rumours)
      assert.deepEqual(Object.keys(rumour).sort(), ["claim", "id", "label"]);
  }
  const o = generate(c, "origin", "visibility");
  const payload = originPayload(o, "a".repeat(64));
  assert.deepEqual(
    Object.keys(payload).sort(),
    [
      "schema_version",
      "world_id",
      "burg_id",
      "enrichment_sha",
      "content_pack_version",
      "record_id",
      "label",
      "text",
    ].sort(),
  );
  assert.ok(!canonical(payload).includes("markers:"));
  assert.ok(!canonical(payload).includes("secret"));
});
test("negative tampering catches source IDs, trait conflicts, materials and disconnected histories", () => {
  for (const d of domains) {
    const ctx = d === "site" ? s : c;
    const r = generate(ctx, d, "negative", options);
    const bad = structuredClone(r);
    bad.source.cell_id++;
    assert.throws(() => validateRecord(bad, ctx), /Identity/);
    const wrong = structuredClone(r);
    wrong.source.culture_id++;
    assert.throws(() => validateRecord(wrong, ctx), /Identity/);
  }
  const a = generate(c, "character", "negative", options);
  a.public.traits = ["cowardly", "fearless"];
  assert.throws(() => validateRecord(a, c), /Contradiction/);
  const m = generate(c, "mundane", "negative");
  m.public.base.material = "plastic";
  assert.throws(() => validateRecord(m, c), /material/);
  const r = generate(c, "rare", "negative");
  r.public.ownership[1].from = "missing-owner";
  assert.throws(() => validateRecord(r, c), /Disconnected/);
  const site = generate(s, "site", "negative");
  site.public.history[1].years_before = site.public.history[0].years_before + 1;
  assert.throws(() => validateRecord(site, s), /history/);
  let damaged;
  for (let n = 0; n < 30; n++) {
    damaged = generate(s, "site", String(n));
    if (damaged.public.structural_damage.length) break;
  }
  damaged.public.structural_damage = [];
  assert.throws(() => validateRecord(damaged, s), /Damage/);
  const noport = structuredClone(c);
  noport.port.value = null;
  assert.throws(
    () => generate(noport, "npc", "forced", { role: "harbour-worker" }),
    /Contradiction/,
  );
  const nofaith = structuredClone(c);
  nofaith.religion.value = null;
  assert.throws(
    () => generate(nofaith, "npc", "forced", { role: "religious-attendant" }),
    /Contradiction/,
  );
});
test("sidecar namespaces, immutable atomic write, pinned identity and prose independence", () => {
  const a = generate(c, "origin", "storage"),
    b = generate(c, "mundane", "storage"),
    e = envelope(w.base, [a, b]);
  assert.deepEqual(verifySidecar(e, w.base, e.enrichment_sha), e);
  assert.throws(() => verifySidecar(e, w.base, "b".repeat(64)), /pinned/);
  assert.throws(
    () => verifySidecar(e, worlds[1].base, e.enrichment_sha),
    /pinned/,
  );
  assert.throws(() => envelope(w.base, [a, a]), /duplicate/);
  assert.throws(
    () => envelope(w.base, [a, generate(c, "character", "storage", options)]),
    /Mixed/,
  );
  assert.throws(
    () =>
      envelope(w.base, [
        a,
        generate(c, "origin", "other", { provider: "lexicon-staged" }),
      ]),
    /Mixed/,
  );
  const dir = mkdtempSync(join(tmpdir(), "game78-store-"));
  try {
    const path = join(dir, e.enrichment_sha + ".json");
    writeSidecar(path, e);
    const bytes = readFileSync(path);
    writeSidecar(path, e);
    assert.deepEqual(bytes, readFileSync(path));
    assert.throws(() => writeSidecar(path, envelope(w.base, [a])), /EEXIST/);
    assert.deepEqual(bytes, readFileSync(path));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  const before = canonical(a),
    p = project(a, knowledge(a));
  const x = render(p),
    y = render(p, { style: "fixed" });
  assert.equal(canonical(a), before);
  assert.equal(a.source.world_id, w.base.id);
  assert.equal(envelope(w.base, [a, b]).enrichment_sha, e.enrichment_sha);
  const upgradedPack = { ...pack, version: "trhgd-game78-next-pack" };
  assert.notEqual(sha(canonical(upgradedPack)), sha(canonical(pack)));
  assert.notEqual(
    new ContentSeed(w.base.id, "world", "test", packSha).digest("x"),
    new ContentSeed(
      w.base.id,
      "world",
      "test",
      sha(canonical(upgradedPack)),
    ).digest("x"),
  );
});
test("linked real POI contract accepts only same-world public site references", () => {
  const site = generate(s, "site", "contract");
  const job = generate(c, "contract", "linked", { site_record: site });
  assert.equal(job.public.related_site.source_id, 51);
  assert.equal(job.public.related_site.cell_id, s.cell_id);
  const cross = structuredClone(site);
  cross.source.world_id = worlds[1].base.id;
  assert.throws(
    () => generate(c, "contract", "bad", { site_record: cross }),
    /Invalid/,
  );
  const hidden = structuredClone(site);
  hidden.source_visibility = "hidden";
  assert.throws(
    () => generate(c, "contract", "bad", { site_record: hidden }),
    /hidden/,
  );
});

test("explicit discoveries require knowledge gates; origin projection remains public-only", () => {
  const r = generate(s, "site", "discovery");
  assert.equal(
    project(r, {
      world_id: w.base.id,
      discovered_fields: [r.id + ":historical_detail"],
    }),
    null,
  );
  const p = project(r, {
    ...knowledge(r),
    discovered_fields: [r.id + ":historical_detail"],
  });
  assert.equal(p.discoveries.length, 1);
  assert.equal(p.discoveries[0].label, "Discovered");
  assert.equal(p.discoveries[0].value, r.secret.historical_detail);
  assert.ok(!canonical(p).includes("repair_account"));
  assert.equal(project(r, knowledge(r)).discoveries.length, 0);
});

test("sidecar rejects rehashed wrong generator/pack labels and duplicate records", () => {
  const record = generate(c, "origin", "pin-negative");
  for (const mutate of [
    e => { e.content_pack_version = "other-pack"; },
    e => { e.records[0].versions.generator = "other-generator"; },
    e => { e.records[0].versions.pack = "other-pack"; },
    e => { e.records.push(structuredClone(e.records[0])); },
  ]) {
    const bad = envelope(w.base, [structuredClone(record)]);
    mutate(bad);
    const {enrichment_sha, ...payload} = bad;
    bad.enrichment_sha = sha(canonical(payload));
    assert.throws(() => verifySidecar(bad, w.base, bad.enrichment_sha));
  }
});

test("compact origin uses stored memory/tradition without changing facts", () => {
  const r = generate(c, "origin", "compact");
  const before = canonical(r);
  const a = originPayload(r, "a".repeat(64), {compact:true});
  assert.equal(a.record_id, r.id);
  assert.equal(a.text, originPayload(r, "a".repeat(64), {compact:true}).text);
  assert.ok(a.text.includes(pack.memories.find(x => x.id === r.public.memory.event).action));
  assert.ok(a.text.includes(pack.traditions.find(x => x.id === r.public.tradition.practice).practice));
  assert.equal(canonical(r), before);
});
