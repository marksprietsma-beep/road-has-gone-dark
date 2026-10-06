# Executed GAME-81 review evidence

Godot 4.6.3 and the existing offline Node 24.19.0 helper. Base GAME-80: `c661d31c41b255384de49a4db7be111b6a3abfc1`. Final UI/render assertions were run after source commit `36f0545`; the final publication commit adds precise owned-job assertions and evidence. CI independently repeats the complete chain on the actual review head.

| Executed proof | Result | Evidence |
|---|---|---|
| JS generation/identity/compatibility | 5 tests passed | [log](logs/generator.txt) |
| Two canonical templates + five freshly generated worlds | Exact replay; immutable world/package bytes | [worlds](generated-worlds.json) |
| Sequential backgrounds | 1,050; 1,050 distinct facts/prose/story combinations; 37 occupations; no declared contradiction/source/visibility violations | [metrics](batch-metrics.json), [raw records](sequential-backgrounds.json) |
| Same-campaign generate/edit/reroll/ready/reload | Passed, zero smoke failures | [log](logs/smoke-party.txt) |
| Actual UI failures, transactional rollback, deterministic retry | 71 checks, zero failures | [log](logs/failures.txt) |
| Recomputed-hash malformed people sidecars | 17 checks, zero failures | [log](logs/reader-failures.txt) |
| Seven-world party lifecycle | 142 create + 56 independent-process replay checks, zero failures | [create](logs/lifecycle-create.txt), [replay](logs/lifecycle-replay.txt) |
| Actual keyboard/mouse/rendered UI, three sizes and fresh world | 112 checks, zero failures; visible origin glyphs, footer, edited name, sibling invariance, menu resume | [log](logs/input-render.txt), [frames](EVIDENCE.md) |
| Complete local native Linux export, both packed presets + fresh world | 29 checks, zero failures; no source helper override, empty PATH, production executable launch | [proof](distribution-proof.json), [log](logs/native-distribution.txt) |
| Existing GAME-7/74/75/76/79/80 regression chain | Passed; no runtime script errors; frozen fixtures/V1/V2 unchanged | [complete runner](logs/complete-local-suite.txt), [regressions](logs/game80-regressions.txt) |

Representative regression counts: GAME-74 3,974 source/save + 27 post-write + 18 real input/render; GAME-75 105,425 context + 109 input/render; GAME-76 57 lifecycle + 21 input/render; GAME-79 6,163 create + 6,161 replay + 10 post-write + 1,922 input/render; GAME-80 2,581 preset/legacy + 2,211 create + 40 replay + 9 post-write + 2,926 input/render. GAME-7 persistence smoke passed. Counts are assertions, not independently distinct scenarios.

The full local runner used previously generated, byte-verified GAME-81 worlds to avoid duplicate generation. Their original helper logs are retained, and CI generates all five from scratch. The full local run's earlier 50-case failure and 83-case visual stages are superseded by the separate final 71-case and 112-case logs above; no failed intermediate visual assertion is presented as passed.

Read the first 100 unfiltered backgrounds and inspected the actual frames. Three prose forms remain recognizable; some generated names and formal phrases need later polishing. Zero exact duplicates does not prove literary quality. Strict full world/save validation still adds latency; the UI runs generation/commit asynchronously and caches only immutable local presence. Windows native automated QA is separate from Mark's hands-on laptop acceptance. Final Windows/Linux artifact links and actual head checks are recorded in PR #65 after CI completion. Nothing is merged; no gameplay or character mechanics are introduced.
