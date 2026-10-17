# GAME-126 — character completeness repair

Status: the bounded GAME-126 competence/skill repair, exact native verification and self-contained Windows package are complete. PR [#117](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/117) records integration status. Character careers and the wider GAME-123/full catalogue programme remain incomplete.

## Scope and concrete repair

Existing32 base classes remain the roster. Immutable v16 adds five trained uses in existing opportunities: Athletics hauls reported stores in one turn, with an upfront provision and higher DC; Stealth attempts access without bargaining away supplies at a higher DC; Acrobatics attempts a faster survey at a higher DC; Spellcraft assesses an arcane interpretation of existing remains; Animal Handling assesses animal behaviour as a possible explanation for reported tracks. Neither investigation invents magic, beasts or world truth. Actions use frozen cycle profiles, existing timing/outcome contracts, deterministic checks and the existing one-award XP/save authority. Contextual trained approaches appear before generic choices; character sheets explain all 14 skills' actual uses. Existing v1–v15 campaigns keep their original options and ordering.

Archmage's former slot-capacity-only requirement admitted a legal Wizard13/INT12 with no legal seventh-tier spell. v16 introduces a generic permanent spell-tier entry projection using owned spells, actual ability requirements, permanent capacities and spontaneous known selections. Runtime grants, forms and temporary effects cannot qualify; spending slots or changing prepared copies does not erase permanent prepared-caster competence. Entry remains an explicit XP-funded player advancement. The original v15 behaviour remains preserved for old pins. A related v16 suggestion fix excludes Duskblade channel wrappers from spell knowledge, matching the existing Spellbook UI and authority.

No new base class, ancestry, feat, spell, save writer, combat engine or quest/map/settlement system is added.

## Breadth versus completeness

Both v15 and v16 define32 base tracks (legal total-level 20),18 prestige tracks (caps3/5/10),37 ancestry families,50 heritage records,82 feats,14 skills,143 unique named spells/198 class references,45 selectable psychic identities,14 creature definitions,15 body forms and228 scheduled career groups.401 other named ability labels/425 records and10 channel wrappers are not425 distinct designs or10 additional spells.

`current/MATRIX.json` separates Indexed, Defined, Selectable, Mechanically functional, Automated-tested and Player-validated evidence. `current/REPORT.md` lists every base class's levels, decisions/repertoire and prestige compatibility. No per-option human validation is inferred. The source ledger still contains760 occurrences/720 normalised rows, including403 ancestry/subrace,66 base-class,283 prestige and8 NPC occurrences.87 previously mapped source occurrences remain scoped adaptations;673 remain unresolved. No sourcebook variant is promoted by association with a similar production class or ancestry.

The previous top-level coverage rollup incorrectly stopped at v13. It now records the verified native v16 delivery and preserves the accepted v15 baseline separately; all720 source rows/760 occurrences remain unchanged.

## Source evidence

Initial broad source receipts retain their exact v16 candidate hash (`5e6bb450…`); the final source skill and earned-journey receipts name `66991484…`. Their scopes and provenance remain separate. A final timing refinement changes Athletics to a one-turn recovery so its net supply yield is not merely the same trade as the existing free recovery checks. The final candidate is `66991484…`; old receipts are retained and are not relabelled as tests of that hash. Final native verification independently regenerated the full witnesses and12 earned journeys for the final candidate; see the exact source and receipts below. Character definitions/counts and v1–v15 bytes are unchanged.

- All 32 base tracks:640 legally replayed levels;588 successful observable direct RulesEffects executions;2581 checks/0;65 exact separate-process snapshot checks/0. This is not all tactical targeting/conditional triggers or every career combination.
- All 576 base/prestige pairs: bounded production-kernel search found485 full-cap routes through total20. Current v16 compatibility replay also validates those485 routes, with 1940 checks/0;78 have single-class entry,53 are bridge-dominated. Every base class has at least one witnessed single-class entry.91 missing bounded-search witnesses are **not** proved impossible. Entry histories, path caps, legal continuation and bridge proportions remain visible in the matrix.
- All 82 feats have lawful selections/derived feature witnesses; all 50 heritage records have birth/body/equipment witnesses.209 checks/0 also include actual Nature/Performance rank counterfactuals. Conditional tactical feat coverage remains partial.
- Competence/skill negatives and positives:818 checks/0, including unknown/negative data rejection, trained rank gates, deterministic successes/failures, costs/reward projection, actual known versus nominal spontaneous spell access, temporary grants and explicit optional prestige entry/decline; cold restart4checks/0.
- Twelve persistent adventurers across Fighter/Rogue/Wizard, Cleric/Druid/Bard, Monk/Duskblade/Spirit Shaman and Psion/Warlock/Lurk parties each earned360XP and reached7 through ordinary objectives. Their actual main actions/attacks replay deterministically; four separate-process campaign reloads pass. Higher-level 20 and exhaustive compatibility examples remain development fixtures, not claimed earned levels.

The Windows workflow additionally exercises original v15 mechanics/channel/rest/restart, historical byte/pin guards, exact legacy/current prestige histories, fresh v16 campaigns, failed-check persistence and all 12 earned identities from a clean export. Its final results and artifact are recorded below.

## Native delivery

- Verified implementation/QA source: `a5ae9072e3399c48959bcd8f38e32e004d14a0d8`. Production presentation/gameplay is unchanged from7e202b1; later source corrections affect QA fixture ingestion only.
- Exact content: `trhgd-character-v16`, SHA-256 `6699148448bcc0d81d9b1b0dee12ebfd48e50569066cf8b73cd1c5bb32d557d7`.
- [Successful Windows-native workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38990886978). All10 applicable implementation-head checks passed; the optional review-package job was skipped as designed. Exact checks/links are in `evidence/verified-source-ci.json`.
- [Download the complete Windows x64 package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38990886978/artifacts/12086302155); [raw native evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38990886978/artifacts/12086157564).
- Playable inner ZIP: `game126-character-completeness-windows-x64.zip`.
- Playable ZIP SHA-256: `e7c2c1d329ae7e6e00ac00ef22e70625e04a5d389e4cb8f58f8d99e30834050f`.

Extract the outer GitHub artifact ZIP, then the inner playable ZIP into a writable folder. Run `road-has-gone-dark.exe` inside that extracted game directory. Keep `worldgen-helper`, artwork/licences and every supporting file beside it; no installed Godot or Node is required. Escape skips the introduction. The inner ZIP contains START-HERE.txt. Existing saves are discovered normally and retain their original pins; do not delete/recreate them. Fresh New Game selects v16. Follow TESTING.md for skills, objective consequences, home advancement and Resume.

| Exact Windows phase | Checks / failures | Separate-process checks / failures |
|---|---:|---:|
| repair | 818 / 0 | 4 / 0 |
| options | 209 / 0 | 136 / 0 |
| audit | 2581 / 0 | 65 / 0 |
| compatibility | 1940 / 0 | 485 / 0 |
| Legacy v15 mechanics | 1662 / 0 | 46 / 0 |
| Exact v15 prestige witnesses | 485 / 0 | Native cold replay of the preserved source fixtures |

The legacy ingestion boundary additionally passes9 strict cases. Each of4 fresh native campaigns has3 actual adventurers,360earnedXP per member and level7; each cold restart has8checks/0. The cohort checks are491, 511, 487, 484, all0failures. All five trained skill outcomes are persisted. Actual tactical action IDs match all12 adventurers; moves/end-turns and companions are not substituted as ability witnesses. The isolated battles exercise existing production combat and deterministic commands; they do not manufacture campaign XP or claim a persisted battle reward. The original full-flow regressions separately exercise combat return/consequences.

`evidence/native-archive-audit.json` independently verifies both AMD64 executables (game and bundled helper Node), ZIP CRC/path/duplicate integrity, absence of the QA executable, exact manifest/content/source provenance, SHA-256 and actual native receipts. Execution used an empty PATH with no source-helper override, including production executable startup. All15 historical pack bytes/pins remain unchanged. The current matrix now derives from exact native class/option/prestige receipts:32×20 legal fixture levels and485 full-cap prestige histories, including78single-class entries and53bridge-dominated routes. These do not prove all conditional mechanics or interesting careers.

The previous failed run38920339237 is preserved as failed evidence. Its legacy-route failure was integral JSON numbers represented as floats in a raw Dictionary comparison; the fixture already had a v15 pin. Existing RulesJson normalization now compares the complete pin, all485 keys and original snapshot hashes, with precise diagnostics and negative tests. No history, expected hash or old pack was regenerated to make the test pass.

Sixteen genuine Godot images are in SCREENSHOTS.md. They use the same final content and unchanged production presentation, with explicitly labelled source render provenance. These are not native screenshot or per-option human-acceptance claims.

Final publication commits after the tested source contain documentation/evidence only; verify `git diff a5ae9072e3399c48959bcd8f38e32e004d14a0d8..HEAD --name-only` is confined to docs. Export staging/presets exclude docs, so these do not change the tested game/helper/content bytes. The verified artifact identifies its actual tested source rather than claiming a newer rebuilt executable.

## Limitations and next repair

Actual spell-score restrictions matter independently of class level or slot capacity. A deliberate Human Sorcerer20/CHA20 satisfies the tier-nine spell requirement; a Dwarf Sorcerer20 that spends every increase on CHA reaches18 and fails CHA19 despite nominal tier-nine slots (43 source checks/0; development fixtures). This may be an intended inherited tradeoff; it must be explained, not represented as universal highest-tier access. The Spellbook's generic10+tier caption also does not describe every preserved legacy spell requirement. Per-spell access/presentation is explicitly in #118; no old rules pins are silently rebalanced here.

Upper-tier spell breadth is thin in some classes (often two class references per tier). Many martial/pact levels add no newly owned action; feats, attributes, passives and scaling mean that is a review prompt rather than an automatic empty-level verdict. Conditional feat/trigger/aura/channel permutations and every creature/form/class combination still require more tactical witnesses. The bounded route solver is not exhaustive and some lawful bridges do not make a satisfying career. All unusual anatomy still uses disclosed neutral humanoid LPC art; environmental vision/flight/aquatic exploration are not claimed. Existing finite authored identities/source-world fixtures remain unchanged.

Prioritise [GAME-128 upper-tier repertoire coherence (#118)](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/118), then [career signatures and conditional feat execution (#119)](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/119). Prestige build guidance and ancestry/source taxonomy continue under the existing programme issues. No new base classes should be added merely to improve counts before these supporting gaps are addressed. GAME-123/#101 and the full programme/#82 remain open.

See TESTING.md for exact reproduction and human playtest steps; screenshots are genuine Godot renders of earned saved characters, not image-generation mockups. Linear is unavailable in this environment; GitHub#116/#101 are the delivery mirrors.
