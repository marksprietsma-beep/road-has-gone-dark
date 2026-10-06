import { loadWorld, context } from "../src/context.mjs";
import { canonical, sha } from "../../game77/src/core.mjs";
import {
  generate,
  domains,
  project,
  pack,
  packSha,
} from "../src/framework.mjs";
import { render, RENDERER } from "../src/text.mjs";
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { gzipSync } from "node:zlib";
const out = "research/game78/evidence";
mkdirSync(out + "/batches", { recursive: true });
const w = loadWorld("tests/worldgen/fixtures/game-11-determinism.json"),
  town = context(w, "settlements", 771),
  site = context(w, "markers", 51),
  metrics = {},
  review = [];
function semantic(r) {
  const p = structuredClone(r.public);
  delete p.name;
  delete p.naming;
  if (p.local_figure) delete p.local_figure.name;
  if (p.contact) {
    delete p.contact.id;
    delete p.contact.name;
  }
  if (p.related_entities)
    p.related_entities = p.related_entities.map(
      ({ id, name, ...rest }) => rest,
    );
  if (p.maker) delete p.maker.identity;
  if (p.ownership) {
    const index = new Map(p.ownership.map((x, i) => [x.owner, i]));
    p.ownership = p.ownership.map((x) => ({
      ...x,
      owner: index.get(x.owner),
      ...(x.from ? { from: index.get(x.from) } : {}),
    }));
    p.repair.after_owner = index.get(p.repair.after_owner);
  }
  if (p.issuer) delete p.issuer.id;
  if (p.target) delete p.target.identity;
  if (p.relationship) delete p.relationship.other;
  return canonical(p);
}
for (const provider of ["sha-staged", "lexicon-staged"])
  for (const domain of domains) {
    const count = ["npc", "contract", "group"].includes(domain) ? 200 : 1000;
    const rows = [],
      texts = new Map(),
      facts = new Set(),
      shapes = new Map();
    const start = performance.now();
    let bytes = 0;
    for (let i = 0; i < count; i++) {
      const ctx = domain === "site" ? site : town;
      const record = generate(ctx, domain, String(i), {
        provider,
        playthrough_id: "batch-78",
      });
      const knowledge = {
        world_id: w.base.id,
        playthrough_id: "batch-78",
        known_entities: [record.id],
        heard_rumours: record.rumours.map((x) => record.id + ":" + x.id),
      };
      const publicProjection = project(record, knowledge),
        prose = render(publicProjection, { extended: domain === "character" }),
        fixed = render(publicProjection, { style: "fixed" }),
        lexicon = render(publicProjection, { style: "lexicon" });
      if (i < 20) {
        if (
          canonical(record) !==
          canonical(
            generate(ctx, domain, String(i), {
              provider,
              playthrough_id: "batch-78",
            }),
          )
        )
          throw Error("Replay");
        if (
          canonical(prose) !==
          canonical(
            render(publicProjection, { extended: domain === "character" }),
          )
        )
          throw Error("Prose replay");
      }
      if (
        /undefined|ancient evil|lifelong sailor|https:|<iframe|The a |A a |They (sets|keeps|counts|listens|pauses|folds|cleans)\b/.test(
          prose.text,
        )
      )
        throw Error("Quality token at " + domain + ":" + i + ":" + prose.text);
      const row = {
        index: i,
        record,
        public: publicProjection,
        render: prose,
        fixed_control: fixed.text,
        lexicon_control: lexicon.text,
      };
      rows.push(row);
      facts.add(semantic(record));
      texts.set(prose.text, (texts.get(prose.text) ?? 0) + 1);
      const fingerprint =
        domain === "origin"
          ? record.public.memory.event + "/" + record.public.tradition.practice
          : domain === "site"
            ? record.public.purpose +
              "/" +
              record.public.history.map((e) => e.event).join("/")
            : domain === "character" || domain === "npc"
              ? record.public.occupation +
                "/" +
                record.public.family +
                "/" +
                record.public.training
              : domain === "rare" || domain === "mundane"
                ? record.public.base.type +
                  "/" +
                  record.public.base.material +
                  "/" +
                  record.public.quality
                : record.domain +
                  "/" +
                  (record.public.type ?? record.public.goal);
      shapes.set(fingerprint, (shapes.get(fingerprint) ?? 0) + 1);
      bytes += canonical(record).length;
    }
    const sorted = [...rows].sort(
        (a, b) => a.render.text.length - b.render.text.length,
      ),
      seeded = [...rows]
        .sort((a, b) =>
          sha("cross-section:" + a.index).localeCompare(
            sha("cross-section:" + b.index),
          ),
        )
        .slice(0, 15);
    const key = provider + "/" + domain;
    metrics[key] = {
      count,
      distinct_semantic_facts: facts.size,
      distinct_prose: texts.size,
      duplicate_prose: count - texts.size,
      distinct_template_fingerprints: shapes.size,
      most_repeated_fingerprints: [...shapes]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5),
      generation_and_three_render_ms: performance.now() - start,
      serialized_fact_bytes: bytes,
      pack_sha: packSha,
      renderer: RENDERER,
    };
    writeFileSync(
      out + "/batches/" + provider + "-" + domain + ".jsonl.gz",
      gzipSync(rows.map((r) => JSON.stringify(r)).join("\n") + "\n"),
    );
    review.push({
      provider,
      domain,
      first50: rows.slice(0, 50),
      seeded_cross_section: seeded,
      shortest: sorted.slice(0, 3),
      longest: sorted.slice(-3),
      repeated_cases: [...texts].sort((a, b) => b[1] - a[1]).slice(0, 3),
    });
    console.log(key, metrics[key]);
  }
writeFileSync(
  out + "/batch-metrics.json",
  JSON.stringify(
    {
      metrics,
      pack_counts: Object.fromEntries(
        Object.entries(pack)
          .filter(([, v]) => Array.isArray(v))
          .map(([k, v]) => [k, v.length]),
      ),
      memory: process.memoryUsage(),
    },
    null,
    2,
  ) + "\n",
);
writeFileSync(
  out + "/review-corpus.json",
  JSON.stringify(review, null, 2) + "\n",
);
writeFileSync(
  out + "/REVIEW-CORPUS.md",
  "# Sequential quality corpus\n\nDeveloper review: includes secret facts in adjacent machine-readable JSON. Public prose below is visibility-projected. First 50 outputs are sequential, never curated.\n\n" +
    review
      .map(
        (r) =>
          "## " +
          r.provider +
          " / " +
          r.domain +
          "\n\n" +
          r.first50
            .map((x) => "**" + x.index + "** " + x.render.text + "\n")
            .join("\n") +
          "\n### Detected extremes\n\n" +
          r.shortest
            .concat(r.longest)
            .map((x) => "**" + x.index + "** " + x.render.text + "\n")
            .join("\n"),
      )
      .join("\n"),
);
