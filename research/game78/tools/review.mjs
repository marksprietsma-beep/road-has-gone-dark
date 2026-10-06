import { writeFileSync, mkdirSync, readFileSync } from "node:fs";
import { loadWorld, context } from "../src/context.mjs";
import {
  generate,
  project,
  envelope,
  writeSidecar,
  packSha,
  pack,
  domains,
} from "../src/framework.mjs";
import { render } from "../src/text.mjs";
const out = "research/game78/evidence",
  w = loadWorld("tests/worldgen/fixtures/game-11-determinism.json"),
  c = context(w, "settlements", 771),
  s = context(w, "markers", 51),
  examples = [];
const site = generate(s, "site", "review"),
  records = [site];
for (const domain of domains.filter((d) => d !== "site"))
  records.push(
    generate(c, domain, "review", {
      playthrough_id: "game78-review",
      ...(domain === "contract" ? { site_record: site } : {}),
    }),
  );
for (const role of [
  "tavern-keeper",
  "toolmaker",
  "local-clerk",
  "traveller",
  "religious-attendant",
  "possible-recruit",
])
  records.push(generate(c, "npc", "role:" + role, { role }));
for (const r of records) {
  const p = project(r, {
    world_id: w.base.id,
    playthrough_id: "game78-review",
    known_entities: [r.id],
    heard_rumours: r.rumours.map((x) => r.id + ":" + x.id),
  });
  examples.push({
    domain: r.domain,
    id: r.id,
    context: r.domain === "site" ? s : c,
    record: r,
    public: p,
    short: render(p),
    extended: render(p, { extended: true }),
    lexicon: render(p, { style: "lexicon" }),
  });
}
mkdirSync(out + "/sidecars", { recursive: true });
for (const scope of ["world", "playthrough:game78-review"]) {
  const e = envelope(
    w.base,
    records.filter((r) => r.scope === scope),
  );
  writeSidecar(out + "/sidecars/" + e.enrichment_sha + ".json", e);
}
writeFileSync(out + "/examples.json", JSON.stringify(examples, null, 2) + "\n");
writeFileSync(
  out + "/public-review.json",
  JSON.stringify(
    examples.map((x) => ({
      domain: x.domain,
      logical_id: x.id,
      text: x.short.text,
      world_id: x.record.source.world_id,
      burg_or_marker_id: x.record.source.id,
      source_kind: x.record.source.kind,
      cell_id: x.record.source.cell_id,
    })),
    null,
    2,
  ) + "\n",
);
const metrics = JSON.parse(readFileSync(out + "/batch-metrics.json"));
const native = JSON.parse(readFileSync(out + "/native/metrics.json"));
const performance = JSON.parse(readFileSync(out + "/performance.json"));
const fresh = JSON.parse(readFileSync(out + "/fresh-worlds.json"));
const title =
  "# GAME-78 combined content-system review\n\nThis is an isolated research implementation. All examples are actual deterministic output anchored to original source IDs. No game mechanics, live quests or canonical world edits. Generated history is explicitly TRHGD fiction; present-day source culture is not proof of historical authorship.\n\n";
let md =
  title +
  "## Breadth and measured quality\n\n| Domain / provider | Records | Name-independent fact variants | Public prose variants | Duplicate prose |\n|---|---:|---:|---:|---:|\n" +
  Object.entries(metrics.metrics)
    .map(
      ([k, v]) =>
        `| ${k} | ${v.count} | ${v.distinct_semantic_facts} | ${v.distinct_prose} | ${v.duplicate_prose} |`,
    )
    .join("\n") +
  "\n\nSemantic counts remove incidental names and owner IDs; they still count genuine changed event/occupation/material/trait facts. Group counts are intentionally modest. [First 50 sequential outputs, extremes and detected repetition](REVIEW-CORPUS.md) and [raw compressed batches](batches/) are durable and reproducible.\n\n";
md += "## Examples: source → structured meaning → public prose\n\n";
for (const x of examples) {
  md +=
    "### " +
    x.domain +
    " / " +
    x.id +
    "\n\nSource: original " +
    x.record.source.kind +
    " ID " +
    x.record.source.id +
    ", cell " +
    x.record.source.cell_id +
    "; " +
    (x.context.display_name ?? "unnamed source entity") +
    ".\n\n" +
    x.short.text +
    "\n\n<details><summary>Structured generated facts</summary>\n\n```json\n" +
    JSON.stringify(x.record.public, null, 2) +
    "\n```\n\n</details>\n\n";
  if (x.record.rumours.length)
    md +=
      "Rumours (truth metadata is developer-only):\n\n" +
      x.public.rumours.map((r) => "- **Rumour:** " + r.claim).join("\n") +
      "\n\n";
  md +=
    "<details><summary>Developer-only hidden truth — excluded from public prose</summary>\n\n```json\n" +
    JSON.stringify(x.record.secret, null, 2) +
    "\n```\n\n</details>\n\n";
}
md +=
  "## Fresh canonical worlds\n\n| Seed | Actual contrasting towns | Actual ruin IDs | Enrichment examples |\n|---|---|---|---:|\n" +
  fresh
    .map(
      (f) =>
        `| ${f.seed} | ${f.contrast_towns.map((b) => b.name + " (" + b.id + ")").join(", ")} | ${f.ruin_markers.join(", ")} | ${f.examples.length} |`,
    )
    .join("\n") +
  "\n\nFive fresh worlds each replay byte-identically through the accepted packaged helper. [Source IDs, hashes and complete examples](fresh-worlds.json).\n\n";
md +=
  "## Recommendation and limits\n\nRetain TRHGD typed facts/seeds and constraints. Use the pinned Lexicon engine where weighting and language generation help, and pinned Rant for public-fact rendering. Adopt only the specifically cleared vocabulary. No vendor fantasy/SRD prose pack enters the content library. See [executed comparison](../docs/PROVIDER-FINDINGS.md), [performance](performance.json) and [architecture](../docs/ARCHITECTURE.md).\n\nThis is substantially broader than GAME-77, but still a research library rather than a finished years-long campaign corpus. The present tone emphasises everyday work and local memory; future authored packs need broader non-craft social history, cultural voices, source-type coverage and editorial acceptance. Names are source-culture-bound approximations. Ruins/dungeons are the supported site anchors; unsupported natural markers fail rather than acquire invented buildings.\n";
writeFileSync(out + "/REVIEW.md", md);
const data = JSON.stringify(examples).replaceAll("<", "\\u003c");
writeFileSync(
  out + "/review.html",
  `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>GAME-78 research review</title><style>body{background:#100f0c;color:#d5bd88;font:17px Georgia,serif;max-width:900px;margin:auto;padding:20px;line-height:1.5}button,select{background:#181610;color:#d5bd88;border:1px solid #77633c;padding:8px;margin:4px;font:inherit}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:13px monospace;border:1px solid #51432d;padding:12px}details{margin:16px 0}small{color:#ac9871}h1{font-size:25px}p{max-width:75ch}</style><h1>GAME-78 · Structured meaning, rendered lore</h1><p>Source-backed anchors; immutable generated fiction. Research only. Hidden truth is visible only in the labelled developer section below.</p><select id="which"></select><main id="content"></main><script type="application/json" id="samples">${data}</script><script>const rows=JSON.parse(document.querySelector('#samples').textContent),menu=document.querySelector('#which'),main=document.querySelector('#content');for(const [i,x]of rows.entries()){let o=document.createElement('option');o.value=i;o.textContent=x.domain+' / '+x.id;menu.append(o)}function block(tag,text){const e=document.createElement(tag);e.textContent=text;main.append(e);return e}function detail(label,value){const d=document.createElement('details'),s=document.createElement('summary'),p=document.createElement('pre');s.textContent=label;p.textContent=JSON.stringify(value,null,2);d.append(s,p);main.append(d)}function show(){main.replaceChildren();const x=rows[Number(menu.value)];block('h2',x.domain.toUpperCase());block('p',x.short.text);block('small','Original '+x.record.source.kind+' ID '+x.record.source.id+' · cell '+x.record.source.cell_id);detail('A — Actual source context',x.context);detail('B — Generated structured facts',x.record.public);detail('Rant prose compared with native Lexicon grammar', {rant:x.extended.text,lexicon:x.lexicon.text});detail('Known rumours — no verdicts in public payload',x.public.rumours);detail('DEVELOPER ONLY — secrets excluded from public projection',x.record.secret)}menu.onchange=show;show();</script></html>`,
);
console.log(
  "Review package:",
  examples.length,
  "examples, typed sidecars, public-only diagnostic payload",
);
