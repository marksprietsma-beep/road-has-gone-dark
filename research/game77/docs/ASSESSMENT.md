# GAME-77 initial engineering assessment

Production base fetched and inspected: `3350aed73aa22f2f144ae4613f054ff81ab0ca34`.
No later main commits. GAME-75 was completed separately; its draft PR #58 is green
on `3cdbd31b9d4a34ebe7211337e7f2112c9a73526f`. Core work starts from main,
not that branch. Do not mutate GAME-75; reconsider a separate integration only
once this core spike passes its own tests.

Exact serious-candidate pins and licence snapshots: `../audit/pins.json`.

- Lexicon core/grammar have sound independent child streams and explicit context.
  Actual five-seed experiments pass repeated-input and sibling-order checks under
  the existing Node 24.19.0 runtime. Core+grammar transformed source closure is
  22,650 bytes / 13 modules, no external runtime dependencies. Markov adds about
  6.6 KB source. Fantasy corpora claim generic roots, but include recognisable
  fantasy names; no row-level source/licence mapping. Reject importing those data.
- Rantjs 3.0 is ISC, explicitly frozen in favour of a successor. Engine-only
  import works with our own dictionary and explicit seeds, including remembered
  carriers. Actual five-seed samples are deterministic. Engine closure is about
  40 KB / 15 modules; full transformed src includes ~970 KB with dictionary data.
  Dictionary lineage is separate from the ISC code; do not import it. Stateful
  instances must get per-entity seeds; the engine does not own our fact schema.
- Fantasy Content Generator 4.9.1 is MIT code with one seedrandom runtime dep.
  README explicitly ties it to D&D 5E and warns to check content-source licences.
  UUID generation calls Date/performance/Math.random despite seeded content.
  Use staged field/dependency concepts, not corpus, IDs, mechanics or runtime.
- Venture is a ~542 MB GitHub repository with Go 1.24.5, seven direct modules plus
  a large indirect/Ebiten/network tree. Reviewed narrative/quest/item/faction
  structures are useful concepts; a second runtime and game schemas are not.
  No code or content is imported. Optional CC0/donor candidates get separate audit.

Initial samples show both grammar engines can emit restrained sentences, but
neither solves the hard problem: deciding and persisting consistent world facts.
Prefer a tiny TRHGD-owned SHA-256 path seed/context/constraint layer, explicit
records and visibility projections, with an original versioned content pack and
simple deterministic rendering. Keep a provider interface so a grammar engine can
be added later if measured authoring needs justify it. Complete comparable
experiments with the donor-inspired staged approach before final recommendation.

Layer A stays byte-verifiable Azgaar. Layer B is immutable enrichment sidecars
pinned by schema/generator/content-pack digest and independent enrichment SHA.
Text is a separate rendering artifact; it cannot create facts. Layer C knowledge
is a caller-provided visibility state, never stored in world enrichment. Starting
character backgrounds belong to playthrough-scoped content, not shared world
history; use explicit playthrough IDs for that proof. Do not change GAME-7 saves.

Prototype a real ruin/dungeon anchor, a real eligible hometown background,
modest mundane and rare items, plus public hometown memory. Original authored
packs only, actual culture/religion IDs or explicit unknown. No new personal-name
corpus until provenance/culture matching is resolved. Preserve vendor notes as
provenance; never execute dungeon iframe/URL or depend on the network.

Storage is lazy explicit research CLI using the existing bundled Node binary,
not a change to GAME-76's production generation pipeline. Sidecar writes are
immutable and collision-checked; version upgrades create new sidecars, never
rewrite campaigns. Measure bytes/dependencies and prove offline replay.

Tests will cover path collisions/order/siblings, many seeds and geography,
contradictions, source identity, tamper/version rejection, rumour/secret gating,
public origin projection and base byte invariants. Produce developer-labelled
HTML/Markdown and actual Godot adapter diagnostics; then relevant GAME-7/74/76
regressions. Integration, if safe, is a separate draft stacked on stable GAME-75.
No gameplay, character stats, mechanics, faction/history simulation or merging.
