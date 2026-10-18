# GAME-144 regression repair

PR [#137](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/137), branch `fix/game-144-v19-regressions`, from merged main `c2a2fdecf12480d3e383d04da1ffe988c9fcd632`. Class/renderer native evidence source `f9b07179df1709b2ba7fb426bc2c68238a818f7c`; subsequent source-guard repair `8f28101f9f35922e3881a41c91de051deb644082`. Production scripts and data are identical across both. The immutable Windows run references below are the merge gates. Their final conclusions and the actual merge/main/post-merge receipt are published on PR137 and issue136; a static run reference is not a completion claim.

## Root causes and exact repairs

| Group | Classification | Evidence and correction |
|---|---|---|
| Wave Two/Four corpus | Outdated exact-source expectation | `tests/character_catalogue/legacy-projection.json` omitted the approved v19 actual-movement condition. Its prior v10/v11 multi-line adapter no longer matched, cascading into4 failures. Register that precise v19-only line first. Original GAME121 `9d12a9057404e898b08f637785397eb95cedffddd162259df5483bd5525779d0` and frozen V1 `0a76f7fb11502ec833416772644c502c777f181259a9ce4ab6da12bd43bb6949` oracles and every prior adapter remain unchanged. `tests/opportunities/corpus.gd` only updates the explanatory wording; all hash and exactly-once assertions remain. |
| Wave Three/Five catalogue | Outdated test authority | `tests/character_catalogue/fresh_driver.gd` inherited `TacticalCombat`, while real campaign cycle commands use `TacticalAuras`. Focused lawful Warblade action reproduces different units/log/hash. The harness stops after its first failed equality, so battle-completion failure is a cascade. Modern catalogue prediction now instantiates the production adapter; exact saved-state equality remains and command/field diagnostics are added. Historical base-engine fixtures remain unchanged. |
| GAME133 capture | Historical/render-only fixture pin mismatch | High-level v18 Druid fixture is copied into a v19 render context. Existing helper changed the owner pin but not the companion's pin; exact nested validation correctly returned `companion.build`. `tests/nature_repertoires/capture_driver.gd` validates the archived source first and projects the same exact pin onto its copied companion. No creature is recreated or replacement ID invented as a remedy. Existing deterministic render-only owner mapping remains; original saves and all other creature fields stay unchanged. |

The failed render's displayed owner was `51f11c116f417755b21f95ea0bdf05ff:adventurer:2`. The underlying archived mechanical fixture owns `a:companion` as `a`; both are already valid at18. The failing condition is the nested pin, not missing real identity. A durable exact fixture under `tests/v19_regressions/fixtures/` records the originating failed run/source/file SHA. Wrong companion IDs and mixed pins are still rejected.

## Focused Windows evidence

[Run39133067045](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39133067045) passed62 focused assertions and7 independent cold-restart assertions, zero failures. Exact phase timings are preserved in evidence/focused-timings.json. [Reproduction](evidence/focused-reproduction.json) records the actual Warblade command, differing fields and `companion.build` error; original18 and render19 complete records, histories, resources and next-command/log/RNG survive restart exactly. These are development fixtures, not earned-level claims.

The first added focused harness had a Variant-inference parse error and was cancelled before full suites. Explicit typing corrected it; the runner now reuses the existing error-watching `checked_process` helper, retains errors and enforces a180s timeout. Cancelled run39129565371 is not counted as successful validation. No expensive complete suite was launched until focused reproduction/cold passed.

## Complete Windows validation

| Required workflow | Evidence run | Tested source |
|---|---|---|
| GAME-133 Sorcerer and Druid Repertoires | [39130378223](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130378223) | f9b0717 |
| GAME-129 Class Signatures | [39130385204](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130385204) | f9b0717 |
| GAME-130 Spell Repertoires | [39130391719](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130391719) | f9b0717 |
| GAME-126 Character Completeness | [39130397740](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130397740) | f9b0717 |
| GAME-112 Character Catalogue Wave Two | [39133460799](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39133460799) | 8f28101 |
| GAME-112 Character Catalogue Wave Three | [39133467909](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39133467909) | 8f28101 |
| GAME-112 Character Catalogue Wave Four | [39133475526](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39133475526) | 8f28101 |
| GAME-112 Character Catalogue Wave Five | [39133482478](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39133482478) | 8f28101 |

Relevant current-head PR checks are reviewed separately before normal merge. Source inspection confirms every production script and all rules JSON bytes including19 equal baseline main; no content, RNG, combat, XP, save writer or player pin changes. [Byte/oracle inspection](evidence/source-inspection.json) is source inspection only; all Godot/game validation runs on native Windows. No Linux game tests or workflows were added or run.

## Next bounded character work

Keep GAME123/#101 and the full character programme open. Recommend **GAME129 follow-up: precision, mobile combat and protection**, limited to Scout/Rogue/Swashbuckler/Knight plus Duelist/Arcane Trickster. Reuse the genuine Scout movement repair already in19; verify/fix once-per-activation precision, ranged/reaction boundaries, equipment restrictions, conditional feats and protection, with explicit permanent prestige prerequisites and earned manual advancement. Do not add roster entries or claim a full disarm/AI-taunt engine. The remaining caster and pact gaps follow the finite READINESS queue. GAME142/141 follows supported-character acceptance, not this regression repair. No next-wave implementation is included here.

No callable Linear connector is available. GitHub mirrors136/101 will carry the verified completion/remaining status; direct Linear updates are not claimed.


## Additional verified native evidence

The complete GAME133 workflow [39130378223](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130378223) passed on the repair source, including14 genuine Godot captures. Archived18 mechanics598/cold31, historic16 repair818/cold4, compatibility1941/cold486, actual production input10, earned journey657/cold8 and connected combat34/cold68 all have zero failures. [Raw native receipt](evidence/nature-native-proof.json). Archive-specific tests retain their own pins; the earned campaign and connected battle use the actual19 default. Three ordinary careers earn490XP/level8; high-level captures remain explicit development fixtures. [Screenshots](SCREENSHOTS.md).

The repaired catalogue native job passed in Waves Three/Four/Five. Its separately pinned11 mechanics1684 and tactical2066, current19 prestige gates146, fresh campaign330 and separate-process fresh checks23 all passed. The fresh campaign actually executes Psion/Warlock/Warblade actions and earns40XP; nine snapshots across three advanced campaign fixtures survive full process restart. [Condensed receipt with raw proof digest and artifact link](evidence/catalogue-native-summary.json). Do not count archived11 mechanics as a current19 roster audit.

GAME130 complete Windows run [39130391719](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39130391719) also passed. Remaining full workflow conclusions must be verified live before merging; all eight immutable repair-source references are in [required-windows-runs.json](evidence/required-windows-runs.json). Any subsequent commit containing only this documentation/evidence is explicitly compared against the tested source before merge, with current-head PR checks reviewed separately. No successful native suite is regenerated merely for documentation.


## Additional full-suite guard exposed and repaired

First complete Wave Two run39130350149 passed the original corpus, frozen rules and progression phases, then failed a second raw-source check in `tests/adventure_cycles/pin_guard.py`. Its preserved source-pins.json expects pre19 combat hash842ff877739787171564ca6d9b6041229accb423bdbff97aaf967ee124ed6990. This is the same approved v19 movement change, masked by the earlier corpus failure, not a new gameplay defect. The guard now verifies the exact reviewed current SHA, requires exactly one explicitly registered adapter restoring that original hash, and checks the restored bytes against the unchanged original pin. No blanket fingerprint update or hash exemption.

`pin_guard_test.py` retains all9 existing manifest/pack/UTF8 negative gates and adds6 negatives: altered legacy code, removed/duplicated adapter, a changed current hash disguising legacy damage changes, tampered restoration text, and missing adapter registration. All15 passed on native Windows in39133067045, alongside62 fresh/7 cold reproductions. A bounded search found only the corpus and this guard actively consuming the changed source contract; older entity/battlefield hashes are provenance for preserved snapshots, not another current-source assertion.

Only the other three legacy runs guaranteed to hit this same guard were cancelled. Their earlier passed native jobs and first failed run remain recorded in evidence/superseded-legacy-runs.json; none are counted successful. All four affected complete legacy workflows rerun on8f28101. Successful GAME130/GAME133 and continuing GAME129/GAME126 native evidence on f9b0717 is reused because runtime/data/tools and every one of their test trees are unchanged. [Exact input/source comparison](evidence/native-source-equivalence.json). No expensive successful suite is relabelled as freshly run on a different source. Post-merge main runs are additionally inspected before resolution.
