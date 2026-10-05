# Interface, storage and version policy

Layer A is the byte-hashed immutable Azgaar file and the unchanged GAME-7 world
reference (`azgaar:1.153.1:<source seed>:<raw SHA>`). The research context adapter
reads source IDs, references, exact flags and verified route-cell points. Unknown
coast remains unknown; a port flag alone never establishes ocean geography.
Current source culture is exact; assigning it to a historic creator is generated
fiction, explicitly labelled as such rather than archaeological proof.

Layer B records have source anchor, scope, schema/generator/pack versions, seed,
structured facts, rumours with truth metadata, private truth, tags and provenance.
Facts are decided in staged generation; TextRenderer consumes them with no RNG
and no access to vendor notes. Original pack data is hashed canonically. No prose
is authoritative. Text artifacts have a separate renderer version/hash.

Layer C is passed to `project(record, knowledge)`, never written into world
sidecars: known entity IDs (knowledge of existence, not precise location), heard
rumour IDs, discovered tokens and optional character playthrough ID. Unknown
sites return null. Hearing a rumour reveals text plus a “Rumour” label, never the
truth verdict. Secrets require the specific reveal token. Public payloads omit
coordinates, vendor notes, provenance and private underground tags. Caller must
obtain knowledge from the eventual authorized game knowledge system; this spike
is not a permissions backend or a new save model.

## Provider-neutral interfaces

- `ContentSeed(worldId, scope, generatorVersion, packDigest).child(entityId)`:
  SHA-256 canonical array encoding avoids path ambiguity; independent labelled
  field choices use rejection sampling. No mutable stream or Math.random.
- `context(world, 'settlements'|'markers', originalNumericId)`: objective context
  with per-field source paths/status. Immutable identity does not use names.
- `generate(type, context, packInfo, {instance, playthrough_id})`: returns facts.
  Future providers must return the same record contract and pass constraints.
- `render(record)`: deterministic prose only; changes do not alter source world.
- `envelope(baseWorld, packInfo, records, {scope})`: sorted, versioned digest.
  Mixed world/playthrough records and cross-world references are rejected.
- `verify(envelope, expectedBaseWorld, optionalExpectedEnrichmentSha)` and `writeImmutable(path, envelope)`:
  integrity/known schema+provider/generator check; atomically publish complete
  bytes using exclusive temporary file + non-overwriting hard link. Same bytes
  are idempotent; different bytes at the same path are a collision error.
- `originPayload(envelope, burgId)`: eight-field public allowlist, no site links.
- Godot `OriginLore.load_projection(path, expected_file_sha)` then
  `get_public(world_id, burg_id)`: accepts only pinned, allowlisted public JSON.
  Wrong world/town returns empty; malformed/digest-failed loads clear stale data.

## Sidecars and ownership

```
world/enrichment/v1/<pack-digest>/<enrichment-sha>.json
playthrough/<playthrough-id>/enrichment/v1/<pack-digest>/<enrichment-sha>.json
```

The CLI demonstrates this under evidence; it does not modify GAME-76 library
folders or GAME-7 saves. World records: site, public hometown memory, world-local
item prototypes. Character backgrounds: explicit playthrough scope plus hometown
and starter index. Two campaigns may share geography/local history, never a
starter's private background. Synthetic `research-demo-001` is explicitly a
research scope, not a real newly created save. No mechanical starter fields.

Exact regeneration needs raw base bytes, scope/entity path, generator source at
its version/pin and exact content-pack digest. Once used, keep those artifacts
and immutable sidecar bytes. A pack or generator upgrade gets a new digest and
sidecar; do not rewrite old campaigns or silently update references. Same pack
version with altered bytes is still a different pack identity and must not be
presented as the old revision. Renderer upgrades may change wording but never
facts/base identity. Persist a renderer artifact/version where exact historical
wording matters. No automatic migration is implemented.

Hard-link atomic publication works on tested native Linux and Windows filesystems;
unsupported filesystems fail explicitly, without a partial authoritative JSON.
A killed process may leave a `.tmp` work file; readers load exact `.json` paths,
never treat those as enrichment. No crash durability/fsync or distributed store
is claimed; those are production-hardening decisions.

## Azgaar flavour and naming

Pinned existing generator `vendor/azgaar/src/generators/markers-generator.ts`
contains site notes and a dungeon iframe/URL assembled from world seed + cell.
We retain raw note/name in developer provenance, not player text. A dungeon
anchor means a source dungeon exists; any vendor dungeon seed is provenance,
not a downloadable interior or runtime dependency. No iframe is rendered.

Culture/religion references use actual source records or unknown. Azgaar burg
names are retained. Personal/maker names are role labels for now: approved
culture-specific NamesBase use or a provenance-cleared pack is future work.
No Lexicon fantasy naming corpus is imported. Encounter tags are possibilities,
not simulated occupants, quests, danger ratings or promises of mechanics.

## Smallest practical next step

Review tone and enlarge original content packs before production scale. If
approved, persist world enrichment once beside a GAME-76 world and a pinned
reference at playthrough creation. Generate character-scoped records only in a
later party-creation task. Wire only public projections to UI. Keep the Node 24
boundary already packaged; no online LLM, second runtime or generator dependency
is needed. Do not automatically implement any of these production changes here.

## Published trial correction

Final source audit found that version 1's research context incorrectly combined
roads, trails and sea routes under road_ids (60 eligible-town sea-route references
in game-11). Current generator **trhgd-staged-2** filters each actual source group
into distinct road_ids/trail_ids/sea_route_ids. Klovskitaue has source sea routes,
not a direct source-cell road in this adapter. Existing GAME-75 factual rules are
unchanged. All 2,565 matrix cases assert the group of every reported route.

This deliberately gets a new generator/seed identity, not silent replacement of
published v1 trial sidecars. Old v1 bytes remain as documented research history;
current examples/projection use v2. No real campaign referenced either trial.

Persisted readers use `readSidecar(path, expectedWorld, expectedEnrichmentSha)`;
it requires the pinned digest and rejects even otherwise-valid newer enrichment.
Envelopes reject mixed generator/pack revisions. Creation-time self-verification
is distinct from loading an established campaign reference.
