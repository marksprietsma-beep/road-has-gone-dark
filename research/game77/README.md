# GAME-77 — deterministic content enrichment research

Based independently on production main `3350aed73aa22f2f144ae4613f054ff81ab0ca34`.
No research-stack merge, canonical mutation, gameplay or character mechanics.

**Recommendation:** keep the small TRHGD-owned structured-fact/constraint/seed
layer and original pack; a fixed renderer suffices now. Lexicon core/grammar is
a reasonable future code-only option if authoring needs grow. No new vendor
runtime, fantasy prose, SRD tables, name corpus or online service is imported.
The existing GAME-76 bundled Node 24.19.0 runs this proof offline.

## Review first

- [Five genuine-context examples](evidence/REVIEW.md): real Ruined Stronghold
  marker 51 / cell 2651, actual eligible Maura burg 771 / cell 1621, character,
  ordinary hand axe, rare workshop survey weight.
- [Developer comparison HTML](evidence/review.html), open locally: source context
  → structured facts → public prose → rumours → explicitly labelled hidden facts.
  **Never feed this document/full sidecar to the player UI.**
- [Machine-readable world and separate playthrough enrichment](evidence/examples.json).
- [Actual Godot public projection, 1280×720](evidence/screenshots/public-origin-1280x720.png).
- [Vendor/licence matrix](docs/VENDOR-MATRIX.md), [exact pins](audit/pins.json),
  [1,000 comparable provider renders](evidence/provider-comparison.json).
- [Architecture and version/storage policy](docs/ARCHITECTURE.md).
- [Tests, tone self-review and limitations](docs/TEST-RESULTS.md).
- [Prepared Linear update](LINEAR-UPDATE.md); no authenticated Linear connector.

## Run

From repository root, use the **same extracted GAME-76 helper**:

```
worldgen-helper/node research/game77/tools/generate.mjs
worldgen-helper/node --import ./research/game77/tests/offline-guard.mjs --test research/game77/tests/framework.test.mjs
```

On Windows use `worldgen-helper/node.exe`. CLI optional arguments are a genuine
canonical fixture path and an output directory. No npm/Python/browser/internet is
needed for enrichment generation. Python is test orchestration only, not a player
runtime. A caller supplies the immutable world and explicit scope/entity IDs.

Full native QA (Godot 4.6.3 + accepted helper required):

```
python research/game77/tools/run-qa.py --helper-contract
```

Add `--visual` with a real display/Xvfb for actual input/render regressions. External
provider experiments are reproducible with pinned source checkouts as documented
in the matrix; they are audit-only and are not dependencies of offline generation.

## Integration boundary

`OriginLore.load_projection(path, expected_file_sha)` returns only a pinned public
payload for an exact GAME-7 world ID + original burg ID. Missing lore is empty,
never substituted from another town. [Payload](evidence/public-origins.json) and
[adapter test](tests/verify-origin-lore.gd) specify the eight-field allowlist.
Factual GAME-75 descriptions remain separate from generated **Local memory**.
No save schema or GAME-76 generation pipeline changes are made by the core spike.

Re-check GAME-75 only after core validation. Any optional demonstration belongs
on `integration/game-77-origin-lore`, based on the published stable GAME-75 head,
with a separate stacked draft PR. Never mutate its branch or take ownership of
its PR. Core success does not depend on integration.

Next step is review of tone, schema and lifecycle, then a small approved original
content-pack expansion and deliberate persisted-reference integration. This PR
does not implement those production recommendations or GAME-10/factions.
