# Wave Four verification

Source `1115aa7722b93a955256ad3b157f2ab201648dad`; v14 hash `3688456544f6e1c0f62e4a26faf5ec114b4ea668e4267cd1bdad3d211cdf8559`.

Native Windows/Linux workflow: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38684785820 . Both dedicated native and legacy restart platform jobs passed. The same run records the broader compatibility matrix. PR99 records current-head checks and publication outcome; merge is gated on successful required checks.

| Native proof | Linux checks/failures | Windows checks/failures |
|---|---:|---:|
| mechanics | 1847/0 | 1847/0 |
| restart | 73/0 | 73/0 |
| journey | 113/0 | 135/0 |
| cohort | 407/0 | 407/0 |
| cohort_restart | 7/0 | 7/0 |
| earned | 273/0 | 273/0 |
| earned_restart | 3/0 | 3/0 |

All native proof references exactly match the final pin. Each package executes gameplay then a separate cold process with empty PATH, no checkout-helper override and actual bundled resources. Production executables also launch independently. Windows downloaded ZIP CRC/content verification and Linux archive verification are recorded in evidence/. Native timings are retained per phase; source timings distinguish import, mechanics, cohort, earned journey, ordinary journey and each cold process.

Source focused checks passed1847/0; additional cohort407/0; independent restart73/0 and7/0. The ordinary source campaign passed143/0 and22/0 reload. The earned prestige campaign passed273/0 and3/0 reload:360 genuine XP across nine opportunity cycles, manual War Chanter entry and saved legal Marshal continuation. Campaign check counts vary with legal generated journeys, so they are reported separately rather than inflated into a combined assertion claim.

Actual Godot creator captures:59/0,45 renders. Campaign/advanced captures:63/0,39 renders. Resolutions640×360,1280×720,2560×1440. Selected unedited images, source commit and SHA-256 hashes are in evidence/screenshots.json. Earned history and labelled development fixtures are distinct; high-level fixtures never claim ordinary earned XP.

Historical source guards:14 installed packs,760 accounted occurrences/720 rows; allv1–v13 pack bytes unchanged and frozen TacticalCombat source unchanged. Append-only pin guard9/0. Earlier06c8bfb frozen oracle evidence recorded22181 kernel assertions,235 migration and6 reload checks, all passing; the final full run reruns the required oracle/legacy suites and remains the authoritative final compatibility record. Historical results are not described as new executions.

## Defects found and corrected

- Fresh native checkout initially lacked Godot's class cache. The source runner now performs a checked editor import; the export QA scene allowlist includes the Wave Four scene.
- Mixed StringName/String allocation keys changed ordered advancement hashes after JSON reload. v14 normalises submitted choice keys at the authoritative preview boundary. Exact history/snapshot invariants remain strict; the regression injects a typed key and verifies input immutability plus exact JSON reload.
- Cognition Adept copied an Erudite-only distinct-power formula from its construction template. That field was removed; a non-Erudite entering prestige has ordinary manifesting access, while genuine Erudite combinations retain their limit.
- Stronger spell probes initially used a level20 target with Will+26; a natural1 still succeeds under frozen numeric saves. Failed-save probes now use a legal low-level target and successful-save probes a high-level target. Both actual effects and successful negation are asserted.
- Creator ancestry probes use the visible suggested-allocation action after inherited Intelligence changes the rank budget. Real Godot previews pass; no production validation was bypassed.

## Reproduction

Use the repository-pinned Godot and matching export templates/helper. Commands: `python tools/character-content/validate.py`; `python tests/adventure_cycles/pin_guard_test.py`; `GAME112W4_TEST_ROOT=<fresh writable path> python tests/character_wave_four/run-tests.py`; native `verify-package.py` in the same directory with `GODOT_BIN` and `GAME76_HELPER_ROOT`. Use a fresh export output; the exporter rejects accidental overwrites. The runner fails on script errors, nonzero exits and timeouts.

Capture scripts use `capture.gd` with `GAME112W4_CAPTURE_ROOT`, `GAME112W4_WORLD_ROOT` and exact `GAME112W4_SOURCE_SHA`. `capture_campaign_launch.gd` uses `GAME112W4_SOURCE_ROOT` containing completed source mechanics/cohort/earned/journey proofs. Set the normal XDG writable roots and helper; use a real display with the compatibility renderer. Unavailable default user-log directories can prevent engine startup, so reuse the configured writable roots. Cold probes must run only after their corresponding saves exist. Raw failed diagnostic attempts remain outside the committed final proof set; assertions were not disabled.
