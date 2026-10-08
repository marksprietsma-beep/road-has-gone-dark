# GAME-32 — versioned character rules core

Proposed ticket contract derived from accepted GAME-17 and the GAME-86 recommendation. Linear ticket text could not be read in this environment; reconcile ticket-specific details before treating this proposal as an accepted scope change. This PR does not implement the contract.

## Responsibility and dependencies

Own legal builds and derived mechanics attached to the existing GAME-81 character IDs. GAME-7 owns playthrough/world identity; GAME-81 owns persisted people/party identity and biography; GAME-84 owns expedition participation. None should be regenerated to obtain combat statistics. GAME-33 consumes a pinned, validated mechanical snapshot, never a second independent class calculator.

Initial content: martial, scout and illusion/control builds, plus one distinct prestige-like progression example. Monk/ranged research kits are test opponents/fixtures; completing a broad catalogue is not an acceptance prerequisite. Progression keeps PF1e-derived vocabulary with explicit adapted 3.5 prestige requirements, without silently running two rule systems or copying proprietary text.

## Inputs, outputs and authority

- `RulesRef = {pack_id, version, content_hash, engine_schema}`; stable ability/class/feat/resource/condition IDs; explicit source/licence metadata.
- `Build = {character_id, rules_ref, level_history[], attributes, skill_ranks, feats[], equipment_refs[], choices, prepared_abilities}`. Every advancement choice refers to a specific step; do not store only the final class label.
- `validate_build(build)` returns deterministic structured violations with stable codes and prerequisite explanations. Validation has no mutation or random fallback.
- `derive_stats(build)` returns HP maximum, defence, attack, saves, stride, initiative, senses, legal ability IDs, capacities and typed modifiers. Condition/current-HP/resource state remains in its proper persistence owner, not recalculated from cosmetic text.
- `preview_advance(build, choice)` returns legal choices and consequences; `commit_advance(expected_revision, choice)` validates again, commits atomically and preserves old data on error.
- Ability definitions declare targeting, main/move/reaction/resource costs, timing, effects, tags, stacking, cancellation and observation behavior. The main/move/no-generic-swift proposal is a rules-pack decision requiring review, not an unnoticed departure from GAME-17's provisional economy.

Mechanics that do not fit the basic effect vocabulary use versioned deterministic hooks with declared inputs/outputs and tests. A single combat function full of class-name exceptions is not the extension mechanism. Modifier stacking, save DC calculation and resource refresh rules must be explicit data/engine rules.

## Compatibility and persistence

Attach mechanics additively to existing character IDs through a versioned record. Existing draft/ready party records without mechanics still load with an explicit “rules build not prepared” state. No silent reroll or invented level history. Pin builds to rules content; a missing/mismatched pack rejects combat preparation with an actionable error. Content upgrades require a previewed migration with preserved source data and checksums, not automatic reinterpretation during load.

Immutable battle input includes the derived snapshot and its hash. Durable HP/resource consumption is not reset when deriving stats again. The initial expedition Focus 2 is a capacity proposal; current Focus belongs to saved mutable character/expedition state.

## Acceptance evidence

1. Three representative valid builds reconstruct identically from the same pinned history; two different character IDs never alias mutable resource state.
2. A base-to-prestige progression retains earlier features and checks every prerequisite. Invalid prerequisites, circular dependencies, missing abilities and stacking conflicts have exact validation codes.
3. Build preview and commit agree; stale revisions fail atomically; save/reload preserves identity, build choices, resources and content pin.
4. An old GAME-81 party loads unchanged; unavailable rules packs fail explicitly rather than assigning default fighter stats.
5. A triggered class feature and a perception/illusion ability use the declared hooks and costs; the content validator catches unregistered triggers and illegal targets before play.
6. Headless deterministic tests cover stat derivation, modifier ordering, costs and progression. No manual/auto-specific stat bonus or bypass.

## Out of scope

Combat UI, tactical AI, changing biographies/worlds, finished character-creation UX, bulk class imports, campaign reward balancing and production combat implementation in GAME-86. Deliver this ticket as a separately reviewed rules-core change.
