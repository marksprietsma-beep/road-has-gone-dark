# Wave Three validation

See DELIVERY.md, CI-EVIDENCE.json and NATIVE-EVIDENCE.json for exact passed results, source pins, failures/corrections, timing evidence and native delivery. Historical packs remain frozen; high-level fixtures are distinct from earned campaigns.

Source: `python tools/character-content/validate.py`, `python tests/adventure_cycles/pin_guard_test.py`, then `GAME112W3_TEST_ROOT=<writable directory> python tests/character_psychic/run-tests.py` with pinned GODOT_BIN and offline GAME76_HELPER_ROOT. The runner treats script/error output as failure and records timings and distinct process restarts. Existing compatibility suites remain in verify-character-wave-three.yml.

Native: `GAME112W3_TEST_ROOT=<writable directory> python tests/character_psychic/verify-package.py` with matching export templates, GODOT_BIN and GAME76_HELPER_ROOT. QA launches with empty PATH and no source helper override; the production executable is separately checked. The Windows artifact is produced and verified natively by CI, not merely cross-exported.

Renders: tests/character_psychic/capture.gd with source-root, capture-root and exact source SHA variables as recorded in the existing provenance. Do not regenerate successful evidence simply to add counts. Selected images, hashes and fixture flags are in SCREENSHOTS.json.

Human journey: extract both archive layers, launch the production executable, create Race/Class builds with Specialisation/Powers, fight using actual costs/targets, return for earned advancement, exit/Resume and compare a historical pinned campaign. Lurk requires veil and melee gear; creature turns/expiry and forms/reversion use the same authority. Advanced screenshots are labelled fixtures; no production XP button is provided.
