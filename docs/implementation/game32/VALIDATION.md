# GAME-32 executed validation and performance

Fresh Godot4.6.3 local execution after the final audit: **22,176 kernel checks, 235 real-campaign migration checks and 6 process-restart checks; zero failures.** The runner compared actual output to the current committed golden oracle, preserved all immutable world-enrichment input hashes and re-executed migration/restart. Thirty independent level20 HP/BAB/save expectations anchor the generated oracle to the V1 formulas.

`python tests/rules/run-tests.py` uses the pinned engine and existing compatible world-generation helper; no new player runtime. Raw logs, `kernel-results.json`, migration summaries and `run-timings.json` are retained beside this report.

| Stage | Operations | Total seconds | Mean ms/op |
| --- | ---: | ---: | ---: |
| Registry load | 1 | 0.008338 | 8.3380 |
| Reference level1–20 progression | 120 | 2.591051 | 21.5921 |
| Advancement previews | 2,000 | 6.630217 | 3.3151 |
| Serialization/derivation round trips | 1,000 | 11.959899 | 11.9599 |
| Compound prerequisites | 5,000 | 0.273314 | 0.0547 |
| Snapshot derivation | 1,000 | 0.963053 | 0.9631 |
| Build validation | 1,000 | 0.584590 | 0.5846 |
| Ability/effect calls | 1,000 | 4.463051 | 4.4631 |

These are observed single-host timings, not frame-time guarantees. Registry parsing/hashing occurs once per registry/process; no stress loop reloads content. Advancement and validation deliberately replay bounded ordered history rather than trusting persisted totals. No per-build cache is necessary at this measured scale; caching mutable character state would create invalidation risks without evidence of a bottleneck.

Stress coverage includes5,000 compound requirements,2,000 legal multiclass previews,1,000 serialization round trips,1,000 derivations,1,000 validations,1,000 ability calls,400 invalid advancements,200 invalid campaign previews and10,000 equivalent RNG draws. Six builds traverse every level1–20, covering pure classes, two multiclass patterns and original prestige entry/continuation. Committed negative fixture patches execute in the validator and have exact error-code goldens.

## Cross-platform evidence policy

[Workflow37716987428](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37716987428) is fully green for first pushed checkpoint `0aee973b22f108ea2f9e95c908cc9ee6339ccd49`. Downloaded Windows/Linux QA artifacts agree exactly on rules pin/content hash, reference derived values, snapshot hashes, RNG sequence hash and negative validation outcomes. Both ran21,115 kernel checks and full GAME-7/81/84/83 regressions. Both complete native distributions passed75 checks with empty PATH, bundled existing helper, production hometown/expedition UI, additive mechanics preparation and ordinary release launch. Archive hashes and the complete distribution proofs are retained in `CI-FIRST-CHECKPOINT.json`.

The later audit deliberately adds snapshot casting/preparation/current-status/maintained fields, more validation and runtime persistence proof; it changes snapshot hashes and expands the golden oracle. First-checkpoint CI is therefore not substituted for validating the final source. A fresh Windows/Linux run must match the current golden file and re-run regressions/native proof. The published draft PR records that final exact-head run, package artifacts and any additional post-publication checks.

## Corrected CI fixture assumption

Run37734198796 passed all22,176 kernel checks on both platforms, then exposed a test assumption: GAME-81 validly generates three of four roles, so an unedited party may have no adept/Focus pool. The Focus-persistence fixture now explicitly selects an adept through the existing GAME-81 party edit API before capturing the old campaign. Production preparation still changes no narrative role or member fact. All migration, byte-preservation, resource-spend and restart assertions remain; no tests or sample counts were removed. Fresh local execution passed235 migration and6 restart checks. Final exact-head CI evidence is linked in the draft PR.
