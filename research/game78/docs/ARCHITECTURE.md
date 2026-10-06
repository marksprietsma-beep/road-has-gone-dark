# Architecture and production integration contract

## Boundaries

`context.mjs` reads unchanged canonical GAME-77 world loaders and adds indexed source-relative population and same/adjacent-cell settlement context. It does not change Azgaar fixtures, accepted generators, GAME-7 schemas or saves. Cell route presence does not imply a specific town gate or navigable water. Coastal/river classifications are retained as source facts, not physical measurements.

`framework.mjs` owns schema 2. Stable seed namespace: world ID + scope + generator/provider + pack digest + source kind/ID + domain/instance + independent field paths. Child sampling never consumes a shared stream. `sha-staged` and `lexicon-staged` are competing fact providers, not compatible identities. Both map to identical TRHGD records. Lexicon names bind every name component to one source-culture ID and original phonotactics; they are research approximations, not authentic Azgaar language data.

`compatibility.mjs` implements declarative all/any/not prerequisites, provided tags and symmetric conflicts. Geography restricts occupations, port-specific memory/tradition, vegetation, materials and training. Explicit negative rules cover orphan/inheritance reconciliation, inland migration explanations and religious/military requirements. No eligible row means an error, never an unrelated fallback. The model is extensible, not a complete world simulation.

Site source anchors are actual public/hidden ruin or dungeon markers. Unsupported natural marker types are rejected. Histories separate occupancy state from damaged structural components: clearing a threshold does not restore an abandoned building, and roof repair does not silently repair a floor. Event years are generated fictional chronology, not Azgaar historical measurements. Ownership transfers have consecutive stable owner IDs and explicit previous-owner edges. Contracts/groups remain labelled unactivated research proposals.

`project(record, knowledge)` is the only public boundary: same-world and character-playthrough checks; sites require an explicit known entity; heard rumours expose claims without truth labels; discovered fields require explicit per-record knowledge tokens and an allowlist. Private facts and vendor source flavour remain outside normal prose. Hidden marker names are not used in origin content. Knowledge is supplied by the caller; this spike does not implement discovery gameplay.

`text.mjs` accepts projections only and rejects incompatible generator/pack/schema/provider pins rather than reinterpreting an older sidecar through current prose tables. Rant singleton dictionaries contain already-established facts; alternatives vary wording. Names use carriers, article/case agreement and conditional branches. Lexicon grammar and a fixed-branch renderer are comparable controls. No renderer decides history, identity or geography. The renderer digest is separate from base geography and fact-pack identity.

## API

```js
const w = loadWorld(canonicalPath);
const ctx = context(w, 'settlements', burgId);
const record = generate(ctx, 'origin', 'local-memory', {provider: 'sha-staged'});
const sidecar = envelope(w.base, [record]);
writeSidecar(versionedPath, sidecar); // immutable, atomic, identical retry allowed
verifySidecar(sidecar, w.base, persistedEnrichmentSha);
const prose = render(project(record, {world_id: w.base.id}));
const payload = originPayload(record, sidecar.enrichment_sha); // existing Godot adapter contract
```

A character requires `playthrough_id`; it cannot share a world-scope sidecar. Contract `site_record` is optional and must reference an actual public marker in the same world. Related NPC/group entities use explicit embedded identities; no unexplained external references.

## Storage and versions

Suggested research-compatible layout: `enrichment/<generator>/<pack-digest>/<scope>/enrichment.json`, separate from immutable `world.json`. Sidecar schema, provider, generator, pack version/digest, record source identity and a caller-pinned enrichment digest are verified. Mixed worlds/scopes/providers, duplicate records and changed pinned bytes are rejected. Creation uses exclusive temp writes and atomic no-overwrite publication; identical repeated writes succeed, collisions fail.

Changing prose does not change the base world or fact pack. A renderer upgrade creates a new rendered artifact/digest. A fact/content-pack/provider upgrade creates a new enrichment identity; existing campaigns keep their pinned sidecars and renderer artifacts. Never regenerate a historical campaign silently. Migration would be explicit and versioned; no migration UI is built here.

## Smallest next production step (not implemented here)

1. Add an explicit optional enrichment descriptor to GAME-76 library metadata, leaving canonical world bytes and GAME-7 origin IDs untouched.
2. Create public-origin records for source-valid hometowns using the same packaged Node helper and publish an immutable schema-2 sidecar plus an eight-field allowlisted Godot projection.
3. Verify base/pack/enrichment/projection pins before the UI loads it. Missing lore falls back to existing factual context; no invented substitute and no creation during UI rendering.
4. Campaigns pin selected enrichment/version/render artifacts. Later lazy NPC/item/site creation uses stable instance IDs and commits records before exposing knowledge. Characters use playthrough IDs.
5. Editorially expand the weakest rumours, contracts and group packs before activating any consumer. Add explicit source/culture naming support rather than presenting approximate research names as established canon.

No player-facing integration is required for the core framework to work. A separate stacked demonstration may consume only precomputed PUBLIC origin payloads without touching GAME-75 or GAME-77 branches.
