# Native First Adventure integration regression

The consolidated main Windows workflow [38407548386](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38407548386) passed geometry recovery, the frozen combat oracle, LPC/battlefields and export, then failed its diagnostic production-fight victory assertion. The actual exported game retained a valid active battle; the automation timed out while choosing only basic attacks.

The old driver selected the retired Adept `spark`, while new campaign recommendations now use genuine Fighter, Ranger and Wizard builds. The current Wizard has a prepared Arcane Bolt. The driver never selected that spell or the other class attacks, so its fight policy was obsolete. This was reproduced locally on the unmodified consolidated main source `94f2c3391844e4dd5fd62310c304733728ce87b0`: the battle remained active at round seven when the unchanged four-minute limit expired.

The repair selects enabled offensive buttons from the live pinned registry and retains basic Attack as fallback. It uses the same production controls, legal targeting, saves and movement path as before. An additional assertion requires the real Wizard spell to have been used. Failed combat actions now report the controller message immediately; a failed victory assertion returns without printing a false victory or cascading into a disabled Return control.

No production scripts, rules, RNG, content packs, campaign pins, XP policy, combat deadlines or regression oracles were changed. Existing legacy-board resume/hash checks, genuine victory/defeat outcomes, art isolation, return-home rewards and save validity assertions remain intact. Dynamic assertion totals depend on the number of UI actions, not a fixed weakened count.

## Local source verification

Godot4.6.3 on Linux, isolated owned save/library roots, exact public seed `first-adventure-review-v1`:

- Before: 240 checks, one failed victory assertion; round seven remained active. Failed diagnostic shutdown errors are retained in the raw log.
- After: 227 checks, zero failures/errors; victory at round four, actual `aimed-shot`, `wizard-arcane-bolt`, `power-strike` and `attack`. Explicit defeat, return-home consequences, exact legacy-board replay/menu reload and saved victories passed.
- Both source runs used the compatible bundled Linux helper override and a normal PATH. They are source validation, not native empty-PATH Windows claims.

Raw before/after proofs and logs are retained beside this document. Native Windows verification and final publication are recorded in the integration delivery after they actually complete. The unrelated ongoing catalogue/UI/party checks continue on the original consolidated implementation; their runtime source is unchanged by this test-only repair.
