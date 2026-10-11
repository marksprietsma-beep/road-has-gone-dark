# GAME-101 audit and save strategy

Baseline: `69fd8c02b2ca235826535bd1f3a7f353591b1a8a`, latest fetched main on 2026-10-11. GAME-98 and GAME-99 are merged. This strategy was recorded before gameplay edits.

The existing sandbox has four source-owned placements, deterministic legal boards, persistent party/rules records, a public knowledge projection, and an expedition controller. AdventureService already supplies a guarded transaction journal and GamePlaythroughStore is the only save writer. The missing parts are activity selection, noncombat decisions and their persistent contracts. Party roles are intentions, not skill bonuses; generated professions are saved facts. No new skill check or random resolver is needed.

## Version boundary

- Freeze `sandbox_generator.gd` and `generation-v1.json`, including board recipes, IDs, source/rules pins and fingerprints. Keep the V1 validator and transition body intact behind version dispatch. Preserve existing V1 results and exactly 10 XP per combat victory.
- New campaigns opt into `sandbox-opportunities-v2` at sandbox preparation. A saved sandbox's version always wins; there is no migration, reroll or reinterpretation of V1 outcomes. Existing campaigns without a sandbox can prepare V2 without changing prior expedition/Old Road history.
- V2 gets its own manifest, generator, validator and transition implementation. It reuses V1's *unchanged legal board composer* through V1 board recipes, with distinct V2 site IDs and seeds. Encounter authority remains TacticalCombat.
- V2 persists an ordered activity ledger, information and explicit results. Each entry binds a site, choice, participant, cost, resource balance and expedition event sequence. Noncombat results earn zero battle XP and carry no fabricated battle hash. Saved terminal combat still grants 10/0 XP and copies actual HP/resources through the existing rules records.
- Every mutation passes through AdventureService's existing lock, journal, validation, save and reload. Expedition revision guards activity submissions; battle command guards remain unchanged. Result publication and the final combat action stay one transaction.

## Small implementation

Use a weighted pool of authored local activity templates conditioned on biome/environment and a verified nearby road. Guarantee a playable mix of recovery, investigation and contested activities, while weighting *templates* and independently permuting their placements. Four opportunities remain a bounded review slice; types are not assigned by site index. Fine local fiction is labelled generated, never canonical Azgaar history.

Recovery can exchange time for provisions and recorded evidence. Investigation trades time/provisions for different information and discovery. Contested access permits a provision payment, inspection, withdrawal or the existing fight. An optional relevant **saved profession** can reduce a defined investigation cost; no ancestry, provisional party-role bonus, invented personal connection or parallel dice engine is involved.

Modify only sandbox dispatch, version-aware AdventureService resume, narrowly permitted V2 expedition event types, and existing expedition choice presentation. Add V2 files/data/tests and a native review workflow. Keep GAME-98 icons/public markers, character generation, GAME-99 geometry recovery and tactical engine unchanged. Legacy diagnostic suites explicitly select V1 when creating their V1 fixtures; production defaults to V2 and existing saved versions route automatically.

## Release gates

Ten actual generated worlds and at least thirty source-owned hometown contexts; replayed fingerprints; measured activity/choice/opponent distributions; multiple saved profession/party compositions; cost and consequence tampering rejection; retry/interrupted-write recovery; mid-activity/restart persistence; real V1 fixture resumed, fought and rewarded; legal maps; shared icon and geography regressions. Capture actual production Godot screens for six hometowns and two contrasting journeys. Export and verify the complete Windows game/helper before linking its playable ZIP and checksum. Draft PR only.
