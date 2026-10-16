# GAME-126 — character completeness repair

Status: draft PR117; source verification complete in the scopes below. Current-head Windows verification and final package are pending. This is not a finished native release or a claim that character careers/the broad programme are complete.

## Scope and concrete repair

Existing32 base classes remain the roster. Immutable v16 adds five trained uses in existing opportunities: Athletics hauls reported stores in one turn, with an upfront provision and higher DC; Stealth attempts access without bargaining away supplies at a higher DC; Acrobatics attempts a faster survey at a higher DC; Spellcraft assesses an arcane interpretation of existing remains; Animal Handling assesses animal behaviour as a possible explanation for reported tracks. Neither investigation invents magic, beasts or world truth. Actions use frozen cycle profiles, existing timing/outcome contracts, deterministic checks and the existing one-award XP/save authority. Contextual trained approaches appear before generic choices; character sheets explain all14 skills' actual uses. Existing v1–v15 campaigns keep their original options and ordering.

Archmage's former slot-capacity-only requirement admitted a legal Wizard13/INT12 with no legal seventh-tier spell. v16 introduces a generic permanent spell-tier entry projection using owned spells, actual ability requirements, permanent capacities and spontaneous known selections. Runtime grants, forms and temporary effects cannot qualify; spending slots or changing prepared copies does not erase permanent prepared-caster competence. Entry remains an explicit XP-funded player advancement. The original v15 behaviour remains preserved for old pins. A related v16 suggestion fix excludes Duskblade channel wrappers from spell knowledge, matching the existing Spellbook UI and authority.

No new base class, ancestry, feat, spell, save writer, combat engine or quest/map/settlement system is added.

## Breadth versus completeness

Both v15 and v16 define32 base tracks (legal total-level20),18 prestige tracks (caps3/5/10),37 ancestry families,50 heritage records,82 feats,14 skills,143 unique named spells/198 class references,45 selectable psychic identities,14 creature definitions,15 body forms and228 scheduled career groups.401 other named ability labels/425 records and10 channel wrappers are not425 distinct designs or10 additional spells.

`current/MATRIX.json` separates Indexed, Defined, Selectable, Mechanically functional, Automated-tested and Player-validated evidence. `current/REPORT.md` lists every base class's levels, decisions/repertoire and prestige compatibility. No per-option human validation is inferred. The source ledger still contains760 occurrences/720 normalised rows, including403 ancestry/subrace,66 base-class,283 prestige and8 NPC occurrences.87 previously mapped source occurrences remain scoped adaptations;673 remain unresolved. No sourcebook variant is promoted by association with a similar production class or ancestry.

The previous top-level coverage rollup incorrectly stopped at v13. It now records the accepted native v15 baseline and separately tracks this v16 candidate; historical/source-variant rows remain unchanged.

## Source evidence

The broad source witnesses below name their exact initial v16 candidate hash (`5e6bb450…`). A final timing refinement changes Athletics to a one-turn recovery so its net supply yield is not merely the same trade as the existing free recovery checks. The final candidate is `66991484…`; old receipts are retained and are not relabelled as tests of that hash. Current-head native verification must independently regenerate the full witnesses and12 earned journeys for the final candidate. Character definitions/counts and v1–v15 bytes are unchanged.

- All32 base tracks:640 legally replayed levels;588 successful observable direct RulesEffects executions;2581checks/0;65 exact separate-process snapshot checks/0. This is not all tactical targeting/conditional triggers or every career combination.
- All576 base/prestige pairs: bounded production-kernel search found485 full-cap routes through total20. Current v16 compatibility replay also validates those485 routes, with1940checks/0;78 have single-class entry,53 are bridge-dominated. Every base class has at least one witnessed single-class entry.91 missing bounded-search witnesses are **not** proved impossible. Entry histories, path caps, legal continuation and bridge proportions remain visible in the matrix.
- All82 feats have lawful selections/derived feature witnesses; all50 heritage records have birth/body/equipment witnesses.209checks/0 also include actual Nature/Performance rank counterfactuals. Conditional tactical feat coverage remains partial.
- Competence/skill negatives and positives:817checks/0, including unknown/negative data rejection, trained rank gates, deterministic successes/failures, costs/reward projection, actual known versus nominal spontaneous spell access, temporary grants and explicit optional prestige entry/decline; cold restart4checks/0.
- Twelve persistent adventurers across Fighter/Rogue/Wizard, Cleric/Druid/Bard, Monk/Duskblade/Spirit Shaman and Psion/Warlock/Lurk parties each earned360XP and reached7 through ordinary objectives. Their actual main actions/attacks replay deterministically; four separate-process campaign reloads pass. Higher-level20 and exhaustive compatibility examples remain development fixtures, not claimed earned levels.

The Windows workflow additionally exercises original v15 mechanics/channel/rest/restart, historical byte/pin guards, exact legacy/current prestige histories, fresh v16 campaigns, failed-check persistence and all12 earned identities from a clean export. Its final results and artifact must be recorded here before merge.

## Native delivery

Pending current-head Windows CI. No v16 Windows download or checksum is claimed yet. The prior Wave Five build is documented in its own delivery and is not this release.

## Limitations and next repair

Upper-tier spell breadth is thin in some classes (often two class references per tier). Many martial/pact levels add no newly owned action; feats, attributes, passives and scaling mean that is a review prompt rather than an automatic empty-level verdict. Conditional feat/trigger/aura/channel permutations and every creature/form/class combination still require more tactical witnesses. The bounded route solver is not exhaustive and some lawful bridges do not make a satisfying career. All unusual anatomy still uses disclosed neutral humanoid LPC art; environmental vision/flight/aquatic exploration are not claimed. Existing finite authored identities/source-world fixtures remain unchanged.

Prioritise a coherent upper-tier repertoire repair, then martial/pact signature progression and conditional feat execution. Prestige build guidance and ancestry/source taxonomy continue under the existing programme issues. No new base classes should be added merely to improve counts before these supporting gaps are addressed. GAME-123/#101 and the full programme/#82 remain open.

See TESTING.md for exact reproduction and human playtest steps; screenshots are genuine Godot renders of earned saved characters, not image-generation mockups. Linear is unavailable in this environment; GitHub#116/#101 are the delivery mirrors.
