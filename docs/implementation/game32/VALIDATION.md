# GAME-32 executed validation and performance

Fresh Godot4.6.3 local execution after the final audit: **22,176 kernel checks, 233 real-campaign migration checks and 6 process-restart checks; zero failures.** The runner compared actual output to the current committed golden oracle, preserved all immutable world-enrichment input hashes and re-executed migration/restart. Thirty independent level20 HP/BAB/save expectations anchor the generated oracle to the V1 formulas.

`python tests/rules/run-tests.py` uses the pinned engine and existing compatible world-generation helper; no new player runtime. Raw logs, `kernel-results.json`, migration summaries and `run-timings.json` are retained beside this report.

| Stage | Operations | Total seconds | Mean ms/op |
| --- | ---: | ---: | ---: |
| Registry load | 1 | 0.007696 | 7.6960 |
| Reference level1–20 progression | 120 | 2.692428 | 22.4369 |
| Advancement previews | 2,000 | 7.249815 | 3.6249 |
| Serialization/derivation round trips | 1,000 | 13.111088 | 13.1111 |
| Compound prerequisites | 5,000 | 0.287863 | 0.0576 |
| Snapshot derivation | 1,000 | 0.955934 | 0.9559 |
| Build validation | 1,000 | 0.621520 | 0.6215 |
| Ability/effect calls | 1,000 | 4.738800 | 4.7388 |

These are observed single-host timings, not frame-time guarantees. Registry parsing/hashing occurs once per registry/process; no stress loop reloads content. Advancement and validation deliberately replay bounded ordered history rather than trusting persisted totals. No per-build cache is necessary at this measured scale; caching mutable character state would create invalidation risks without evidence of a bottleneck.

Stress coverage includes5,000 compound requirements,2,000 legal multiclass previews,1,000 serialization round trips,1,000 derivations,1,000 validations,1,000 ability calls,400 invalid advancements,200 invalid campaign previews and10,000 equivalent RNG draws. Six builds traverse every level1–20, covering pure classes, two multiclass patterns and original prestige entry/continuation. Committed negative fixture patches execute in the validator and have exact error-code goldens.

## Cross-platform evidence policy

[Workflow37716987428](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37716987428) is fully green for first pushed checkpoint `0aee973b22f108ea2f9e95c908cc9ee6339ccd49`. Downloaded Windows/Linux QA artifacts agree exactly on rules pin/content hash, reference derived values, snapshot hashes, RNG sequence hash and negative validation outcomes. Both ran21,115 kernel checks and full GAME-7/81/84/83 regressions. Both complete native distributions passed75 checks with empty PATH, bundled existing helper, production hometown/expedition UI, additive mechanics preparation and ordinary release launch. Archive hashes and the complete distribution proofs are retained in `CI-FIRST-CHECKPOINT.json`.

The later audit deliberately adds snapshot casting/preparation/current-status/maintained fields, more validation and runtime persistence proof; it changes snapshot hashes and expands the golden oracle. First-checkpoint CI is therefore not substituted for validating the final source. A fresh Windows/Linux run must match the current golden file and re-run regressions/native proof. The published draft PR records that final exact-head run, package artifacts and any additional post-publication checks.
