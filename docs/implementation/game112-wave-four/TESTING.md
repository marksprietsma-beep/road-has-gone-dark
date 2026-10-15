# Verification checkpoint

Current v14 hash: `6d900d396bc07c7eb16516a56d744f33708c51e099eec025476e57bf9f56b87f`.

- Focused source mechanics:1692 checks/0 failures, all28 base careers through20, Erudite/auras/powers/feats/spells/forms/creatures and explicit prestige progression. Separate process restart:69/0, exact snapshots including advanced prestige, maintained aura/form and spent Erudite ledger.
- Frozen GAME-32:22181 kernel,235 migration-create and6 reload, all0 failures. Historical append-only pin guard9/0. All13 historical pack files byte-identical to merged main.
- Real Godot creator:26/0,18 renders across640×360,1280×720,2560×1440 before the final compact-summary presentation change; recapture is pending. This caught and corrected duplicate Erudite starting defaults. Raw cleanup warnings are retained.
- Actual new-class campaign: normal writer/three new base classes/earned adventure worked, but five high-level development fixture saves failed because the inherited harness replaced a Bugbear record with Human ancestry. The fixture now preserves the campaign's ancestry and reports actual writer errors. Rerun pending. No production validation was bypassed.
- Native Windows/Linux, final current-head full compatibility, final package/checksum and post-merge acceptance remain pending. Candidate mappings are not promoted to playable.

Commands: `python tools/character-content/validate.py`; `python tests/adventure_cycles/pin_guard_test.py`; `GAME112W4_TEST_ROOT=<writable path> python tests/character_wave_four/run-tests.py`; native `verify-package.py` in the same directory with pinned GODOT_BIN, matching export templates and GAME76_HELPER_ROOT. The runner fails on script errors as well as exit codes and records process timings. Native runs use empty PATH/no source-helper override and independent cold restart.

Advanced histories are explicitly development fixtures. The production journey starts with0 XP and earns actual rewards; no XP button or selector grants XP. CI retains the earlier frozen, legacy, creator, earned, source and native suites. See the Wave Four workflow for the complete matrix.
