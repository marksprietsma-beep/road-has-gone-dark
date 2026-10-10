# GAME-96 audit and architecture decision

Verified local and GitHub GAME-95 head `988d285bf2761f9c421dc79772e523e6c83e7ab0`; draft #74 remains open/unmerged. Main is separately managed. No integration, history rewrite or merge is performed. The uploaded GAME-96 handoff is authoritative. Existing verified Godot 4.6.3, Node/helper, rendered-test tools and Windows CI are reused; no new setup configuration is required.

## Reuse

- Canonical `GameWorldTemplate` returns copies of Azgaar geography and stable entity references. GAME-62 owns original cell geometry, dry-land ownership, routes and the local map. GAME-77–80 source/enrichment separates source truth, inferred presentation and generated fiction.
- GAME-84's existing helper already creates eight deterministic, original-cell-owned dry-land placements, verifies original geography replay, and provides a public regional SVG. Reuse those validated positions and map; do not generate another world or regional geography. Its fixed site/knowledge namespace and immutable cache must remain compatible with old saves.
- GAME-81 party IDs, GAME-32 prepared records, shared LPC recipes/previews and GAME-95 renderer/pacing are reusable. GAME-86 research supplies design direction, not nonexistent charge/cover/delayed-magic rules. Combat paths/LOS/AI/actions already read dimensions; keep their algorithms unchanged.
- `PartyService.operate/commit` owns locks, exact-byte recovery journal, validation, atomic save and immediate reload. Extend its existing validation chain and AdventureService routing; do not write saves from generation/UI.

## Hardcoded assumptions

`first_adventure` permits exactly one result/history entry and two fixed bandits. `TacticalCombat.create/validate` pin registered Old Road boards and exactly five actors. Regional UI always offers that authored fight, regardless of a site's type. It cannot serve as an extensible repeated-adventure ledger without breaking old data. The existing expedition state pins eight legacy sites and must not silently be repurposed.

## Smallest credible extension

1. Add an optional, versioned sandbox record containing immutable generated base data (world/home/cell/region-placement/source pins, seed, site identity, map recipe and encounter spec) and explicit mutable knowledge, encounters, outcomes and per-character journey history/XP. Preserve old expedition/adventure records; reuse the expedition clock/log and existing writer.
2. A deterministic pure generator composes authored terrain/obstacle pieces and bounded enemy compositions. Sites reuse proven GAME-62/84 positions; source parent biome and actual route proximity condition art/archetype choices. Fine terrain, camp/ruin history and hostile occupants are marked generated/inferred, never Azgaar canon. No cave/interior claim.
3. Register generated boards through a pinned v1 recipe with bounded rejection/retry, connectivity/spawn/engagement validation and exact regeneration. Use the same `TacticalCombat` constructor/commands, existing level-one lightly armed Vanguard/Scout opponent builds, dynamic actor count, and unchanged movement/LOS/attack authority. The old board bytes, battle seed and commands stay unchanged.
4. Extend the current hometown/map/site/result UI, with a default procedural entry and concise opportunities. Legacy review drivers opt into the old fixture explicitly; old active saves resume unchanged. Shared combat scene reads the active encounter through AdventureService, keeping existing art/timers/controls.
5. Generate once, persist before play, and reject content/version drift. Resolved victories/defeats/withdrawals retain final encounter state and cannot reroll or duplicate rewards. Leaving a site before combat remains unresolved and revisit uses its same base. Tactical withdrawal remains the engine's terminal defeat; V1 does not reset that encounter. Return home provides explicitly labelled V0 HP/Focus recovery for another local expedition, not injuries/death or progression rules.
6. Multi-world/contrasting hometown corpus, independent frozen combat oracle, malformed/corrupt candidates, failed-save recovery, separate-process reload, multiple opportunities, actual rendering and native Windows exported journey prove the slice. Report real distribution and rejected candidates rather than selecting only pleasant seeds.

Review delivery follows the user's normal **Publish draft PR** flow. Prepare the branch and review description without calling `gh pr create` or publishing a PR automatically. No merges or force pushes.
