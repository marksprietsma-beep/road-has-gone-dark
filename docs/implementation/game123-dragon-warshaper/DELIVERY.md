# GAME-167 native Windows delivery

Dragon Disciple and Warshaper are technically accepted against immutable v34 at source `dc05904b69b2cb72c56408e791575d19d8eadf81`. The same50-career roster now has **47 COMPLETE / 3 PARTIAL / 0 BLOCKED**. This is bounded original gameplay, not exhaustive tabletop conversion or human balance acceptance.

## Exact release

[Successful Windows native workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40668915970) · [Windows x64 download](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40668915970/artifacts/12815966537) · [original evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40668915970/artifacts/12815776985). Artifacts have90-day retention and need repository access.

Inner playable archive: `dragon-warshaper-windows-x64.zip`.

SHA-256: `8297ff208f4b553d0947f1a41b2a9aa4aa1b79cbc34161e29df51723486dbd5d`

Character rules: `trhgd-character-v34`, content hash `4aa4f90021457421bd08b3cb4210f94844651472f7c54e330f5e0055a395e98e`. All historical v1–v33 bytes/pins remain unchanged. Later delivery/readiness/evidence commits may reuse this exact release only while all runtime/export/verification inputs remain identical; strict source guards enforce that condition. Merge/main CI is recorded on [tracked issue167](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/167), closed only after actual successful integration; parent101/GAME-123 stays open.

## Reproduced defects and corrections

- Aggregate arcane levels could satisfy Dragon’s nominal tier-three gate with only tier-one spells. Require permanent actual arcane tier3, prior level5 and Arcana4; never a temporary bonus.
- An otherwise qualifying caster had no legal authored casting-parent option. Select an actually existing arcane base parent explicitly; advance only its own progression once per two prestige levels. Wizard preparation, Sorcerer permanent knowledge, attributes and separate slots stay distinct.
- Untagged Dragon breath bypassed the existing transformed-body supernatural suppression. Tag the existing class actions correctly; no combat engine change.
- Warshaper’s training defence was swallowed by anatomy’s existing training bonus. Existing higher frames now provide actual stacking defence. Longclaw has real reach3; Ironhide trades that reach for physical resistance2. Neither heals or overwrites the owner.

The existing ten Dragon levels provide real scales/unarmed claws plus finite Ember, self Scale mantle, Weakening breath and clustered Crownfire choices. Actual saves, fire resistance, independent condition saves, main actions, finite uses, spacing and body suppression apply. Five Warshaper levels offer paid three-global-round Predatory, Longclaw and Ironhide bodies through the original form authority, with original HP, ancestry, history, equipment and creatures retained and restored correctly. Prestige remains optional earned advancement and is never a starting class or automatically assigned.

## Actual native evidence

The exported EXE independently earned **2280XP/total16** through228 real rewarded objectives/57 cycles: Sorcerer6/Dragon10, Druid11/Warshaper5 and Wizard6/Dragon10. Three separately funded entry/actually committed decline forks survive process restart. Original adventure rewards are never injected or duplicated. Connected combat exercises paid class actions, real Wolf/Sentinel damage, saved active form, deterministic next command, normal resolution/reward and home recovery. Total20 alternatives are explicitly DEVELOPMENT FIXTURES, not earned20.

| Native phase | Checks | Failures |
|---|---:|---:|
| pins | 69 | 0 |
| probe | 146 | 0 |
| mechanics/proof.json | 878 | 0 |
| mechanics/restart-proof.json | 73 | 0 |
| input | 97 | 0 |
| sentinel-probe | 35 | 0 |
| sentinel-campaign/proof.json | 121 | 0 |
| sentinel-campaign/restart-proof.json | 10 | 0 |
| journey/proof.json | 2697.0 | 0.0 |
| journey/restart-proof.json | 11 | 0 |
| connected/proof.json | 113 | 0 |
| connected/restart-proof.json | 38 | 0 |
| capture | 60 | 0 |
| audit/proof.json | 2598 | 0 |
| audit/restart-proof.json | 65 | 0 |
| current-upper/proof.json | 1634 | 0 |
| current-upper/restart-proof.json | 97 | 0 |
| historical33/proof.json | 1086 | 0 |
| historical33/restart-proof.json | 84 | 0 |
| historical33-input | 51 | 0 |
| historical32/proof.json | 1789 | 0 |
| historical32/restart-proof.json | 237 | 0 |
| historical32-input | 53 | 0 |
| historical31/proof.json | 1343 | 0 |
| historical31/restart-proof.json | 145 | 0 |
| historical31-input | 72 | 0 |
| historical30/proof.json | 1143 | 0 |
| historical30/restart-proof.json | 49 | 0 |
| historical30-extended/proof.json | 642 | 0 |
| historical30-extended/restart-proof.json | 37 | 0 |
| historical30-input | 141 | 0 |
| historical29/proof.json | 1290 | 0 |
| historical29/restart-proof.json | 125 | 0 |
| historical18/proof.json | 599 | 0 |
| historical18/restart-proof.json | 31 | 0 |
| legacy/proof.json | 818 | 0 |
| legacy/restart-proof.json | 4 | 0 |
| compatibility/proof.json | 1941 | 0 |
| compatibility/restart-proof.json | 486 | 0 |
| frozen | 22181 | 0 |

Counts belong to their individual phases; they are not summed into an inflated unique assertion total. Receipts and original PNG hashes are preserved in evidence/native-proof.json. The source-only predecessor receipts retain their own source and genuine reused-component provenance.

The independent static archive audit verifies inner SHA, CRC, safe/unique paths, AMD64 production and bundled Node executables, exact source identity, current core/manifest/canonical pin, required licence/credit notices and absence of a shipped QA executable. Actual Windows execution proves empty-PATH startup and independent cold continuation; no Godot runs on the audit host. The all34 pack probe verifies bundled raw bytes and exact pins, not just a copied external manifest.

## Human test instructions

1. Download the GitHub artifact. Extract the outer archive, then the inner `dragon-warshaper-windows-x64.zip`.
2. Keep the entire extracted folder and run `road-has-gone-dark.exe`. No installed Godot, Node or artwork is needed. Escape skips the intro.
3. Fresh New Game uses v34. Existing campaigns retain their exact earlier rules and mechanics without silent migration; they do not automatically receive v34 rule changes.
4. Create Sorcerer, Druid and Wizard characters. Review race/culture/background independently, real skills/feats, caster choices, companion, repertoire and equipment. Neither prestige path is a starting class.
5. Earn adventure XP and return home. Wizard5 can choose or decline Dragon at250XP; Sorcerer6 and Druid6 reach their respective optional entry at360XP. Choose Dragon’s actual caster parent explicitly. Continuing a legal base class remains available.
6. In combat compare paid breath/ward/debuff/cluster choices, saves and exhaustion. Compare Longclaw range with Ironhide mitigation, natural attacks, equipment suppression, reversion and expiry without free healing. Move, summon/transform, then click the gold End with zero main/move. Confirm real creature activations.
7. Resolve, return home, rest, save, fully exit and Resume. Observe unchanged identities/history and restored legal resources. See screenshots/README.md for earned versus development evidence.

## Remaining limitations and stopping point

Existing humanoid LPC anatomy/creature fallback and shared long-label/small-window clipping remain. No flight, custom dragon/animal art, new form engine, world/browser/monster/pantheon or additional career content is claimed. Automated Windows evidence is not testing on the user’s PC. Remaining partial careers are Eldritch Knight, Shadowdancer and Dwarven Defender; no work on them is part of this run. No callable Linear connector was available; verified GitHub status is authoritative for this handoff.
