# GAME-144 Windows verification

No Linux game tests/builds. Source-host Git/JSON/hash inspection is distinct from native execution. All Godot/executable checks run on Windows CI.

## Focused reproduction

Use the existing verified Windows setup/import steps in `.github/workflows/verify-v19-regressions.yml`. With `GODOT_BIN` pointing to the verified Windows engine and `GAME144_ROOT` an isolated test directory, run `python tests/v19_regressions/run-tests.py`. Exact scene: `res://tests/v19_regressions/review.tscn`. The runner uses the existing checked_process helper, preserves errors and terminates a failed diagnostic process promptly. It requires positive checks/zero failures in both fresh and cold receipts.

It constructs a lawful Warblade development record, executes the same command through the old base predictor and actual production adapter, proves the former differs and the latter replays exactly without input mutation. The actual archived Druid fixture reproduces companion.build when only its owner is repinned. The real renderer then preserves IDs, complete creature mechanics, history and resources while projecting both exact pins; wrong IDs/mixed pins remain rejected. Original18 and projected19 records, battle validity and the exact next command/log/RNG survive a separate process. No XP is granted.

Focused run39130096235:62 fresh checks/7 cold checks, zero failures. First draft39129565371 was cancelled due an explicitly corrected typed-Variant parse error; it is not passing evidence.

## Complete required acceptance

All five previously failing complete workflow classes (Waves2/3/4/5 and GAME133), plus dedicatedGAME129, GAME130 and GAME126, are dispatched once on repair source f9b07179df1709b2ba7fb426bc2c68238a818f7c after focused success. See evidence/required-windows-runs.json for exact run IDs and immutable source. All must pass before normal merge; no original assertions, sample counts, source oracles, exact-save checks or historic pins are removed. Check dependent jobs as well as native prerequisites. Relevant current-head PR checks are additionally reviewed.

Before merging documentation/evidence-only follow-ups, `git diff --name-only f9b07179df1709b2ba7fb426bc2c68238a818f7c HEAD` must contain only docs/ paths. Verify no changed scripts/, data/rules/ or test code is being attributed to older evidence. Verify main has not acquired untested runtime changes, mark PR137 ready and normally merge with the exact reviewed head; never force or bypass checks. Inspect all resulting main Windows runs and resolve any actual failure before recording completion.

## Human review

Use the self-contained Windows artifact from the verified dedicated GAME129 run linked in the delivery/issue. Extract both archive layers, keep all support folders/helper/licences, and launch road-has-gone-dark.exe without installed Godot or Node. Continue an existing campaign: identities, original pin, owned creatures and saved combat must remain intact. Fresh campaigns retain v19 and its actual class actions. This regression repair changes no production rules or saves. Character balance/readability and other class-readiness gaps remain GAME123, not acceptance claims of this test repair.
