# Executed GAME-80 validation

Native Linux: Node 24.19.0, Godot 4.6.3 official `7d41c59c4`, software OpenGL/Mesa under Xvfb. No tests below are inferred from previous tasks. Raw logs and machine-readable evidence are committed alongside this record.

| Executed check | Result | Evidence |
| --- | --- | --- |
| New profile Node suite | 10 passed, 0 failed | `logs/profiles.txt` |
| Original V1 compiler suite and byte goldens | 7 passed, 0 failed | `logs/compiler-legacy.txt` |
| Preset profiles + legacy campaigns + read-only columns | 2,581 checks, 0 failures | `logs/presets.txt` |
| Five real generated worlds: import/dual-pin save/reload | 2,211 checks, 0 failures | `lifecycle-create.json` |
| Independent-process restart, corruption refusal, exact restoration, old campaigns, deletion/dedup | 40 checks, 0 failures | `lifecycle-replay.json` |
| Deliberately corrupt profiles after save write | 9 checks, 0 failures | `logs/postwrite-profile.txt` |
| New actual keyboard/mouse/render pass | 2,926 checks, 0 failures; 16 states and 22 towns, three resolutions, 25 frames | `visual-proof.json`, `screenshots/` |
| Complete native export | 11 lifecycle checks, 0 failures; production release launches | `distribution-proof.json`, `logs/native-distribution.txt` |
| GAME-79 lifecycle create/restart | 6,163 / 6,161 checks, 0 failures | `regressions/game79/lifecycle-*.txt` |
| GAME-79 forced post-write lore failure | 10 checks, 0 failures | `regressions/game79/postwrite-lore.txt` |
| GAME-79 actual UI comparison | 1,922 checks, 0 failures; 22 towns at three resolutions | `regressions/game79/input-render.txt` |
| GAME-75 actual source context | 105,425 checks, 0 failures; five independent source audits passed | `regressions/game75/` |
| GAME-75 actual UI | 109 checks, 0 failures | `regressions/game75/visual.txt` |
| GAME-76 packaged helper | 6 genuine generations, repeat/different seeds, exact SHA, safe argv and immutable fixtures passed | `regressions/game76/helper-linux.txt` |
| GAME-76 library lifecycle / actual UI | 57 / 21 checks, 0 failures | `regressions/game76/library.txt`, `visual.txt` |
| GAME-7 persistence smoke | Passed world/save IDs, origin, skeleton records, knowledge/mismatch checks, immutable fixtures | `regressions/game76/game7.txt` |
| GAME-74 source/save / forced reload failure / actual input | 3,974 / 27 / 18 checks, 0 failures | `regressions/game76/game74.txt`, `reload-failure.txt`, `game74-visual.txt` |
| Canonical JSON / landmark taxonomy, key, inspector and hidden-information protection | 5 canonical JSON tests and all landmark checks passed | `regressions/existing-regressions.txt` |
| Original bytes against verified GAME-79 base | 65 compiler/runtime/pack/vendor/preset/fixture/main-scene files byte-identical | `immutability-proof.json` |

The post-write test damages the V2 descriptor only after the campaign write. Confirmation remains an error state; no saved claim or success handoff occurs. Retrying retains the same single slot. Back cannot abandon a written pending campaign. Restoring the exact package finishes that slot; there is still exactly one file, with both pins reloadable. This complements the original GAME-74/GAME-79 failure regressions rather than replacing their assertions.

Five `game80-world-0` through `game80-world-4` worlds were generated using the bundled Node with PATH/NODE_PATH/NODE_OPTIONS empty. Each profile directory replays byte-exactly; a separately generated same-seed world has the same canonical SHA and enrichment descriptor. Total review coverage: 149 states, 1,482 regions, 3,031 eligible hometowns across both presets and all five worlds. The full 50/100/200 sequential engineering reading and disclosed repetition metrics are in QUALITY-REVIEW.md and batch-quality.json.

Profile compilation, including original V1 generation, took 1.48–1.98 seconds per fresh world in this Linux environment. V2 storage was 2.34–2.85 MB per world. These are observed build times, not calibrated gameplay distances or Windows performance promises. UI reads persisted projections and caches profiles per immutable world.

All frames came from real Godot rendering. Inspected the six-frame contact sheet, state and region frames, town comparison, confirmation and handoff. Added a regression after a screenshot caught a stale list highlight; list selection, profile, facts and marker now agree. Added focus settling to the input harness and tightened small-layout bounds after a two-line region tag pushed the footer down. Existing test journeys were adapted to the explicit region step; their original persistence, geography and visibility assertions remain intact.

Native package proof uses the same source/resources in an isolated release export with a diagnostic entry point because official templates prohibit scene overrides. It uses the adjacent helper, no source override or system Node, generates a world, publishes both packages and saves/reloads. The normal release receives its own launch check. Diagnostic files are removed before the complete game/helper archive is written. Godot and helper/dependency notices accompany the distribution.

Remaining review: Windows laptop visuals and narrative acceptance by Mark. Native Windows/Linux CI results and current-head artifact links are recorded in the PR after completion. Linux software rendering reports unsupported VSync; the legacy GAME-79 comparison also reported an ObjectDB teardown warning after its checks passed. These are disclosed warnings, not script errors or evidence of Windows acceptance. No merges or acceptance-state changes were made.

A final co-location audit corrected six unsupported maritime profiles: a coastline elsewhere in the state/region plus an inland lake/river port is insufficient. A ninth regression deliberately recreates that case. The batch independently checks every maritime livelihood/outlook against the actual source burg coordinates and ocean adjacency, rather than trusting generated tags. All 112 current cases are supported. The updated 350-row review includes nine changed public records, which were re-read; unchanged records retain the prior engineering review. Final tests/screens/package are rerun against the refined runtime.

The final tenth Node regression and independent batch assertions preserve recorded hometown classes. All 3,031 source-class associations were checked; all 58 changed public sequential-review records were re-read after the wording correction. Original V1 bytes and eligibility remain unchanged.
