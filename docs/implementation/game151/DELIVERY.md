# GAME-151 narrow Windows regression repair

PR [143](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/143), based on main `813bf519dc2d33d42e87c44021157ce911aad965`. Final merge SHA, Windows conclusions and artifact URLs are recorded on the PR and [milestone101](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/101); do not infer completion from this source checkpoint.

## Historical capture

GAME-130's actual successful v17 mechanics records have legal matching Wizard schools and Cleric Healing domain choices. The capture repinned a duplicate to current v23, whose high-level Wizard/Cleric grants require four additional explicit runtime fields even with zero selected copies. Missing `wizard-unweaving-tide-prepared`, `wizard-stillness-lattice-prepared`, `cleric-concord-release-prepared` and `cleric-renewing-benediction-prepared` produced `runtime.resource_missing`. Hybrid effective casting levels did not grant those pools.

The diagnostic helper validates the original under its exact historical registry, replays unchanged permanent choices under the display pin, and permits only new zero-capacity prepared-copy fields set to zero. It then requires full current validation. It rejects unavailable/forged original pins, incompatible permanent choices and every other missing resource. No shared slots/copies are refilled, abilities granted, saved records migrated or original assertions bypassed. Original source records and their exact native hashes are retained. Focused Windows:206 checks plus14 separate-process restart checks, zero failures. See [TESTING.md](TESTING.md) and `evidence/`.

## Review timeout

GitHub's original check annotation explicitly reports maximum40m0s exhaustion, not a source/test failure or manual cancellation. Every test/export/upload succeeded; the job was cancelled at40m04s, with approximately15m48s spent in full-history checkout. Change only timeout40→60. No steps/coverage or checkout semantics are removed; the job remains bounded. Verify full completion of the branch run and actual postmerge run before declaring this repaired.

## Release boundaries

No production scripts, v1–v23 content or save mechanics change. Rules remain v23 (`e47c16b87f175d589b040984067146a13db4625fdfa2cada130815c730da8ffd`); readiness20 COMPLETE /30 PARTIAL /0 BLOCKED. Original19 green parent checks and full GAME-150 native/corrected Godot evidence remain historical, not fresh repair assertions. No Linux game validation, new classes, v24 or psychic implementation. Existing visual limitations documented by GAME-150 remain.

The existing self-contained Windows release remains [39423972908 / artifact12267518393](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39423972908/artifacts/12267518393); inner `game150-upper-prepared-windows-x64.zip` SHA256 `777260318d9763c1352fb78d54c6d8645927d00f8e48c6bd9119f529ff4351b3`. Its gameplay inputs are unchanged. The repaired review/GAME-130 workflows also publish native Windows packages; final main-run links/checksums belong in the final PR acceptance record. Extract the outer artifact then inner game ZIP, retain all supporting folders, and run `road-has-gone-dark.exe`; no Godot/Node installation required.

Next proposed bounded cohort is Psion, Wilder and Cerebremancer: selected powers, augmentation costs, surge trade-offs and independent hybrid resources. First recover and test existing capabilities. GAME123 remains open; no broader milestone completion claim.
