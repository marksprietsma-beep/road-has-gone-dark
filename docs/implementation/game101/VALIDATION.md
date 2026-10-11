# GAME-101 validation and procedural variety

## Corpus

Ten independent Azgaar seeds `game101-variety-00` through `game101-variety-09` were generated twice. Original world and original geography bytes match exactly between independent replays. Forty hometown contexts (four per world) supply 160 opportunities. Every placement matches the verified GAME-62/84 original-cell-owned dry-land content; no source-coordinate approximation or fabricated geography is used. The corpus chooses differing biomes, not merely differing town names.

| Activity | Occurrences |
| --- | ---: |
| Abandoned shelter | 33 |
| Scattered supplies | 20 |
| Traces of old work | 28 |
| Unusual traces | 23 |
| Occupied shelter | 18 |
| Contested salvage | 27 |
| Verified route obstruction | 11 |

Families: 53 recovery, 51 investigation, 56 contested. There are **18 distinct four-template sets** across forty hometowns. Terrain environments: 84 dry, 36 forest, 36 grass and 4 upland opportunities. This is a source-biome coverage sample, not an estimate of production-world abundance; upland evidence is limited to one hometown. A coverage constraint deliberately retains all three families at every hometown. Variation comes from weighted templates, verified-route eligibility, placement, actual saved professions and tactical recipes, rather than from unlimited new objectives.

Measured choices over two distinct real saved party compositions: 208 careful, 208 quick, 320 withdrawal, 112 negotiation, 112 observation, 112 fight and 296 occupation-specific contributions. These are available-choice counts, not claims that every party or every opportunity offers a companion hook. All choices are reproduced from actual saved profession data. Hostile compositions: 16 paired bows, 14 blade/bow pairs, 11 paired blades and 15 single blades. Board sizes: fourteen 8×6, thirteen 10×8 and twenty-nine 12×8.

Only the 56 hostile sites contribute to the encounter distribution: all four existing opponent combinations and all three legal board sizes occur. Non-hostile sites' unused potential board recipes are excluded from those opponent counts. The corpus passes 1,693 generation, geometry, provenance, protected-source and replay checks. Full counts, hometown/source IDs, coordinates, activity IDs, board hashes and base hashes are retained in `evidence/metrics.json` and CI artifacts. The same generation inputs reproduce identical bases, IDs and choice dictionaries. Previewing all alternative paths on real saved campaign states reproduces identical resulting-state hashes without mutating saves or tactical RNG.

## Reliability and compatibility

- A genuine V1 GAME-99 save resumes without changing its original bytes, party or base fingerprint; its remaining encounter can be fought, rewarded, returned from and reloaded through the production UI and native export. V1 combat retains 10/0 journey XP and cannot reroll.
- Separate-process V1 create/replay: 24/124 checks. V2 activity create/replay/combat restart: 52/26/61 checks. Different branch outcomes, real recovery, careful investigation, saved observation, withdrawal and combat are exercised independently.
- Injected save-write and immediate-reload failures restore exact prior bytes. A published consequence with an uncleared real before/after journal recovers exactly once. Stale retries and repeated resolved-site clicks are rejected without changing save bytes.
- V2 results, world deltas, information, provision balances, XP and contributor histories are reconstructed and validated. Tampered rewards, provision cost/balance, participant, information, battle hash and world consequences are rejected.
- Actual battles retain their pure engine command hash and RNG over save/reload; V1 generator/manifest, TacticalCombat, WorldPeoples, party/local runtime manifests and shared icon semantics have protected source hashes.
- Existing First Adventure combat and campaign-create/reload tests pass. The GAME-32 kernel passes 22,181 checks and its migration/restart passes 235/6 checks against the existing frozen golden values.
- Twelve existing geometry/cache/shared-icon Node tests pass, including canonical replay of the original GAME-99 failing source, malformed geometry rejection and recovery-cache interruption/idempotence. No geometry or icon implementation was changed.

Actual graphical production review passes 719 checks across six hometowns and two generated worlds. A new process restores all six outcomes in 36 checks. The native Linux export passes 623 journey checks and 30 fresh-process checks with empty PATH and no helper override. Windows and Linux native CI both pass 623 journey checks and 30 fresh-process checks. Verified artifact/checksum links and source matching are recorded in DELIVERY.md.

The detailed checks are in `tests/opportunities/run-tests.py`; production controls and fresh-process restore use `review.tscn`, and `verify-package.py` runs those same paths through an exported native executable with empty PATH and no helper override. The Windows artifact is published only after that verification succeeds.

## Honest limits

Four local opportunities remain a bounded slice, drawn from seven authored templates; this is not an endless event engine. Time has no newly invented survival penalty, provisions remain journey-local, and hometown return retains existing V0 preparation/rest. Quick assessment has a deterministic limited-information outcome; it is not a parallel random danger/skill roll. Peaceful access leaves opponents in place and grants no battle XP. Withdrawn/defeated attempts close without claiming the objective or enemy defeat. There is no new economy, inventory, injury, faction, relationship or advanced tactical system.

The preserved V1 fixture is an existing public GAME-99 recovery campaign. The player's private earlier world at vertex 11702 has not been independently identified or reproduced; this task does not claim otherwise.
