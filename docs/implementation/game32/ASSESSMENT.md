# GAME-32 engineering assessment

Implementation-authorised by Mark's finalise-GAME-86 / GAME-32 rules-core brief. Production base: reviewed GAME-83 `bc6f301f6458f992a16c1a201a381376d536b80c` (draft PR67, green native Windows/Linux regressions). GAME-86 design input is read-only at `ddffbdf59d65e8f3b5b9e14c07591f2b1b47ecbb`, now published as draft PR68. Its 209 groups/19,456 battles, raw artifact hashes and generated report were verified without rerunning the experiment suite. Nothing is merged.

## Current contracts and constraints

- GAME-7 `GamePlaythroughStore` owns validated, atomic campaign saves. Its characters are skeletal persistent records with stable IDs; the top-level validator supports additive optional data.
- GAME-81 `PartyRecords` intentionally validates an exact member schema: do not append mechanical fields to party members or change role/background/people/biography. Mechanics belong in a separate versioned campaign record keyed by existing character IDs. Vanguard/Scout/Adept/Expert remain narrative role IDs.
- GAME-84 extends the same party service, journal, save validation and world lifecycle guard. Expedition revision/log, knowledge, supplies, pins and clock must survive mechanics preparation unchanged. Reuse its existing transaction path, not a second save directory.
- GAME-83 is presentation-only. This task adds no combat scene, grid/pathfinding/LOS, initiative queue, AI, autoresolve or character-creation UI. Rules run inside Godot; no new helper/runtime. Existing helper continues to serve world/party/expedition generation.
- GAME-86 supplies movement/main/one-shared-reaction vocabulary. Cost, movement, cover/engagement penalties, spell timing, perception and interruption descriptors are data; geometry/pending battlefield effects remain GAME-33 responsibilities. Research-kit HP/range values are not final class constants.
- Authenticated Linear tools are not exposed. The user-provided detailed GAME-32 brief is the requirements authority in this session; ticket-specific live text/status could not be independently read. Prepared milestone updates will record this limitation without inventing an issue transition. GAME-86 is requested In Review; GAME-32 is reported already In Progress.

## Architecture to implement

A validated immutable registry loads `trhgd-rules-v1` once, hashes canonical integer-safe content and pins schema/rules/engine/provenance. Independent modules own safe formula/requirement ASTs, typed modifier stacking, keyed RNG/structured dice, generic effects/resources/statuses and an explicit trusted hook registry. No executable content strings or class-name branches.

A character kernel replays exact level-order history against prerequisites and choice budgets, derives values/resources/abilities and emits deeply immutable hashed snapshots. Three original reference paths plus an original illusion prestige proof exercise the same generic APIs through total level20. Current HP/resources/statuses live in a mutable record separately from derived capacities.

Deliberate preparation previews deterministic standard-array builds for the same existing character IDs and current role recommendations. Save commit checks exact campaign revision/hash and preserves all previous campaign data. Old saves without mechanics still mean “not prepared”; pinned unavailable/mismatched packs fail explicitly. Invalid advancement/effect/migration must leave the source state byte-equivalent.

## Validation and delivery

Negative content fixtures, exact derived fixtures, all-level/multiclass/prestige cases, real GAME-81/84 save migration/recovery, and deterministic cross-platform golden outputs are required. Stress minima: 5,000 requirements, 2,000 advancements, 1,000 serializations, hundreds of invalid attempts and a large RNG/dice comparison. Profile registry loading, build validation, derivation, requirement/advancement/effects; do not reparse content per call.

Run relevant GAME-7/81/84/83 regressions and dedicated Windows/Linux CI. Use existing native export/template and empty-PATH package proof to verify the hometown/expedition flow. Record observed execution, not hypothetical package success. Push incremental milestones and publish a separate draft GAME-32 PR against GAME-83; stop for review without merging.
