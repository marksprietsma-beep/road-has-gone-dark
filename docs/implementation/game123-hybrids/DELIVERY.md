# Duskblade / Archmage Windows delivery

Existing [PR149](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/149), based on merged mainc48d6df. Complete native Windows [release40115102249](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40115102249) PASSED at exact source `ee7d29a5a6fca0742d7d10e28b958ca1ce077f1b`. Later delivery/readiness edits do not alter gameplay/test/export inputs; the evidence gate checks this. PR149 was normally merged as `c796043aa2543bcab144e8d0353628c35c2ab610`; all22 post-main Windows workflows passed, including historical Wave4 run40150066253 and Wave5 run40150066255. No native release was repeated.

[Self-contained Windows x64 download](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40115102249/artifacts/12569448673) · [native evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40115102249/artifacts/12570473438) · [original screenshots](screenshots/README.md).

Inner playable ZIP `duskblade-archmage-windows-x64.zip` SHA256:
`c34345dab51eb6672ad646b20fdb797677814709ee9dda5a12ba3743f3f3f40f`

Extract the GitHub artifact ZIP, then the inner playable ZIP. Retain every supporting file and run `road-has-gone-dark.exe`. No installed Godot or Node is needed; Escape skips the intro. Existing campaigns resume without deletion or migration. [Exact human testing steps](TESTING.md).

## Corrected mechanics

- Channel buttons/highlights/clicks follow the existing known-spell, melee-weapon, action and original-slot authority. All10 supported channel spells retain real hit/miss/critical outcomes and counterplay.
- Archmage Force DC uses the permanently selected Wizard/Beguiler INT or Sorcerer CHA track, never an arbitrary highest attribute or runtime grant.
- All six high-arcana abilities are supernatural and suppressed by incompatible forms, then restored by real reversion.
- Existing Ward3 additionally clears Weakened/Arcane tether; Ward5 also clears Slowed/Unsteady concentration/Stillness lattice. Finite costs, separate temporary-HP buffer and three-boundary defence/resistance remain. No universal cleanse, healing, resurrection or free resources.

Immutable28.0.0 hash `fc35bee60a75732fe57954efb676eb5ac03fb1a386059518110831b62d33e86f`. All1–27 bytes/pins and original TacticalCombat/RNG/campaign writer remain unchanged. No new roster/spell/feat/creature/equipment definitions.

## Earned failure and real progression

Original run40080757725 failed: the test planner assigned Sorcerer INT8, leaving Spellcraft3 at13 while Arcana10, focus feats and true tier7 knowledge were present. Permanent Spellcraft10 correctly rejected Archmage. The failed save is unchanged; no prerequisite, XP policy or respec bypass was added. A lawful starting array CHA15/INT12 fixes the new test plan. Small original-record Windows reproduction passed106/22 cold; canonical StringName fixture-key handling preserves identical authoritative snapshots. [Full diagnosis](EARNED-FAILURE.md).

Fresh Windows source-Godot40107828256 passed1971 earned/8 cold and37 connected/79 cold checks: three characters genuinely earned1690XP/14 through169 objectives; Wizard/Sorcerer manually chose Archmage1 and could decline. Source controls/captures40113020677 passed41 checks/21 PNGs. These are source evidence, not exported-native claims.

This exported executable loaded that exact unmodified1690XP campaign under runtime/planner/raw-save hashes, committed AND declined actual first prestige entry in four verification forks, cold-restarted them, and earned270 more ordinary XP to1960XP/15 (Duskblade15, Wizard13/Archmage2, Sorcerer13/Archmage2). The original14-level histories remain unchanged. Connected actual channel/Force/Ward, deterministic next command, resolution, home recovery and cold restart passed. No XP was injected or repeatedly awarded for completed objectives. Total20/path5 coverage is separately labelled development fixtures.

## Actual native results

| Exported-game phase | Warm checks | Cold checks | Failures |
|---|---:|---:|---:|
| mechanics | 1594 | 183 | 0 |
| journey | 408 | 8 | 0 |
| connected | 37 | 79 | 0 |
| audit | 2600 | 65 | 0 |
| current-upper | 1634 | 97 | 0 |
| historical27 | 1749 | 175 | 0 |
| historical18 | 598 | 31 | 0 |
| legacy | 818 | 4 | 0 |
| compatibility | 1941 | 486 | 0 |

Additional exported phases:23 production-control checks;363 pinned27 diagnostics;97 original-planner checks/22 cold;30 actual funded entry/decline checks/13 cold;41 capture checks/21 PNGs. The22,181 frozen GAME32 assertions ran in the Windows source-Godot oracle, explicitly separate from exported execution. Every phase passed. [Raw proof](evidence/native-proof.json), [timings](evidence/native-timings.json).

Independent static ZIP/PE/hash audit passed:7022 archive entries, AMD64 production executable and bundled Node/helper, CRC integrity, exact manifest/content/source,121 credit/licence files, QA executable absent. Actual native ordinary startup and empty-PATH execution passed. [Audit receipt](evidence/archive-audit.json). No Linux Godot validation.

Historical archived18 display replay40080945336 passed31 checks/14 original renders without rewriting original JSON/saves: only new unselected zero-capacity prepared pools are added to render-only copies. Historical27 source guard now preserves its exact prefix/bytes and selects27 explicitly when28 is appended; no historical assertion is disabled.

## Readiness and limits

Evidence-gated **35 COMPLETE /15 PARTIAL /0 BLOCKED**, fixed50-career roster. Only Duskblade/Archmage are freshly accepted; the prior33 retain their original source-labelled scope. Duskblade supports20 levels; Archmage supports5 prestige levels and legal total20 combinations. COMPLETE is bounded technical acceptance, not full tabletop conversion or human balance/usability approval. Historical pins intentionally retain original behaviour, including earlier advanced DC/body/Ward mechanics.

Generic scrolling/clipping, empty non-score Attributes sections, large unavailable-prestige explanations, downed/target presentation and nonhumanoid art remain known separate limitations. GAME123/GitHub101 stay In Progress/OPEN. No callable Linear connector is available; GitHub101 supplies the accurate status handoff without claiming direct Linear writes. Next bounded pair: Mystic Theurge/Abjurant Champion, tracked separately in GitHub150.
