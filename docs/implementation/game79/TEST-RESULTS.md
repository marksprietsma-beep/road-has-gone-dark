# Executed verification

Godot 4.6.3; packaged Node 24.19.0. Full local command: `GAME76_HELPER_ROOT=<matching-helper> DISPLAY=<Xvfb> python tests/world_enrichment/run-tests.py --visual --regressions`. The final complete local run exited successfully. Raw output is retained in `logs/`; no failed/unrun check is counted as passed.

| Executed contract | Result |
|---|---|
| Production compiler, exhaustive presets, independent fields, immutable retries, bad vendor/missing renderer/wrong pack | 7 tests passed |
| Two presets + five fresh generated worlds, all eligible hometowns | 3,062 hometowns; 6,163 create assertions passed |
| Second-process persistence, corruption refusal, saved-pin protection, exact legacy restoration, deletion and failure rollback | 6,161 replay assertions passed |
| Post-write lore failure: no handoff/false claim/deletion/duplicate; exact restoration retries same slot | 9 assertions passed |
| Actual Godot keyboard/mouse and rapid A/B/C/A; map/facts/lore alignment; full confirmation/handoff | 1,589 assertions passed across 22 towns and 640×360, 1280×720, 2560×1440 |
| Existing GAME-75 factual context | 105,425 assertions + 5 independent source audits passed |
| Existing GAME-75 actual input/render | 108 assertions passed |
| GAME-76 native offline helper | 6 genuine generations, exact accepted fixture SHA, same/distinct seed, safe arguments and timeout passed |
| GAME-76 library lifecycle / actual input-render | 57 / 20 assertions passed |
| GAME-7 persistence smoke | Passed: independent IDs, origins, skeleton party, knowledge, mismatch refusal, fixture integrity |
| GAME-74 source/save / failed reload / actual input-render | 3,973 / 26 / 17 assertions passed |
| Canonical JSON and landmarks | 5 tests; all 36 macro types; key/inspection smoke passed |

Both canonical fixture digests remained unchanged: game-11 `2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5`; atlas `9f942b07bb73c2af17c4039d009561b696864e02ec67f2e8dd3a5ef6a757ebb3`. All five fresh worlds were enriched using the packaged binary with PATH/NODE_OPTIONS/NODE_PATH cleared. Repeat-seed geography and descriptor/projection bytes matched exactly after independent process invocation.

The source implementation at `0b5c27a` passed Linux and Windows production enrichment, context and library jobs, onboarding, GAME-7 and the regional-generator proof. The older conditional review-package job was skipped intentionally; GAME-79's own matching-helper archive upload is enabled. Final publication checks are linked on draft PR #63 and independently verified before handoff; documentation/evidence commits do not change the validated source or pack.

## Timing and limitations

`platform-timings.json` records actual Linux/Windows CI annotations; `generated-worlds.json` records local full-process timings and storage. These include compiler startup, integrity checks, structured generation, prose, replay validation and transactional file publication. There is one reused native Node runtime; no new runtime dependency tree. Preset enrichment plus projection totals approximately 3 MB; future domains are dormant.

The inspected screenshots are genuine Linux Godot/llvmpipe frames. Native Windows generation/persistence/source regressions passed in CI; Mark's Windows laptop visual acceptance remains a separate review. llvmpipe reports unavailable V-Sync, and the screenshot harness can warn about ObjectDB instances at immediate process shutdown. Neither is a runtime script error; functional assertions and complete regressions passed. No unsupported-version migration UI is implemented: mismatched packages fail clearly and retain campaigns. Only public Origin V1 is active; character creation, Continue and gameplay remain deferred.
