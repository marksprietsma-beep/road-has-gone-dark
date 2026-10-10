# Sandbox spine v1 generation and persistence contract

## Authority and replay

`SandboxGenerator` is pure GDScript composition over the existing verified GAME-62/84 regional packet. No Node helper or world-generation code changes. Canonical hometown, parent cell, province, source biome and eligible road/trail proximity anchor each site. The old eight-site placement packet and SVG remain byte-pinned by the existing expedition record. Four placements rotate through these proven owned dry-land positions. Fine terrain, occupants and disused structure history are explicitly inferred/generated; no canonical Azgaar story, cave, coast or interior is claimed.

Seed = canonical SHA-256 of `[version, configuration-file SHA, canonical world-source SHA, hometown ID, parent-cell ID, original content SHA]`. Stable site ID = `sandbox-site:` plus hash of `[version, world ID, hometown ID, parent-cell ID, original placement slot]`. Opportunity ID hashes version/site ID. Each site recipe has an independent hash of the base seed/site ID. Domain picks hash `seed:domain`, take the first seven hexadecimal digits and modulo the declared count. No generation operation reads/consumes a tactical dice counter. Battlefield attempts add `:attempt:N`.

Configuration is `data/sandbox/generation-v1.json`. The delivered `sandbox-spine-v1` algorithm and configuration are immutable: future incompatible generation changes require a new version and explicit compatibility policy. Saved base data is never replaced during resume. Store validation regenerates map recipes; service resume and every generated operation also reproduce the base from its independently pinned original packet. A self-resealed coordinate edit therefore fails at the service boundary. Configuration/source mismatches produce a visible error and preserve save bytes.

## Structured maps and encounters

Four opportunities per hometown: camp, ruined work-yard, hostile clearing, and a roadside threat only if an eligible source road/trail passing through the parent cell lies within two world units of that placement. Otherwise the fourth is a camp/clearing. The ruined yard begins rumoured; scouting reveals its persistent position. Public map projection omits rumoured sites and their coordinates.

Sizes: 8×6, 10×8, 12×8. Broad source-biome presentation: forest, dry/desert/savanna, upland (non-dry/non-forest source height ≥60), otherwise grass. These are broad inferred local treatments, not micro-biome classification. Three authored grove/boulder/broken-wall pieces compose flanks, ruins have stone courtyard ground, source-road sites have two road lanes, camps have a fire/cart. A seed can reverse deployment 180°. Optional isolated approach pillars change ranged LOS while leaving flank routes. Ground colour has no invented movement/cover modifier.

Three connected approach lanes prevent enclosing walls from trapping the existing greedy enemy AI. Units have short initial separation; every companion is at most seven cardinal path steps from an opponent. Validate nonoverlapping/unblocked spawns, one connected walkable component and engagement distance. Invalid candidates are rejected in seed order, at most eight attempts. Exhaustion visibly fails without saving or silently dropping an opportunity. The generator does not randomize every tile independently.

Opposition uses existing level-one recommendations and lightly armed builds only: one blade, blade+bow, two blades, two bows. Existing recommendation attributes/classes/feats, unarmoured weapon selection and one resolver own all mechanics. Enemy IDs are site-scoped and permanent. This is a small armed-humanoid slice, not a new bestiary or calibrated encounter-budget system.

The first corpus exposed three stalled greedy-AI fights in enclosing ruin pieces. The fix changed composition constraints, never the tactical path/AI/rules algorithms. Bounded retries remain supported; final measured rejection counts are reported separately from this pre-fix diagnostic.

## Save ownership and consequences

Optional `sandbox` record: version/revision; immutable base+hash; mutable knowledge, encounters, results, active journey and per-companion placeholder XP/history. Existing `expedition`, `first_adventure`, party and world records retain their schemas. AdventureService routes pure sandbox candidate transitions through PartyService's existing campaign lock/journal/atomic writer/immediate verification. No new save writer. Numeric normalization is confined to the new namespace/mechanical records, preserving legacy enrichment descriptor types.

Departure/scouting/travel/return reuse the expedition clock/log and four provisions. Combat is saved before entry; every real command goes through the same resolver and writer. Final command, result, knowledge, world delta and character history/reward are one transaction. Victory awards exactly 10 journey XP per companion; this is a placeholder, not levelling. Results validate against the terminal encounter/log/world delta. Histories/XP are reconstructed from ordered results to detect duplication or lost consequences.

Leaving before combat preserves visited knowledge and the same unstarted base for revisit. Tactical withdrawal is the existing terminal defeat: survivors, HP, positions, dice and log remain recorded. A resolved defeat/victory cannot restart or silently respawn in V1. Unresolved in-progress combat resumes exactly. Return home explicitly provides V0 HP/Focus recovery to enable another opportunity; injury/death/rest rules are future work. Persistent character IDs, appearance recipes and previous results never regenerate.

Old active authored journeys resume through the original path. New normal play offers local opportunities rather than a required Old Road quest. Regression drivers explicitly select the authored fixture; its registered board bytes and frozen outcomes remain intact.
