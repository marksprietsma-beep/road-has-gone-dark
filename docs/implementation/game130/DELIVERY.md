# GAME-130 delivery

Ten executable spell choices for existing Wizard/Cleric tiers4–7, in immutable `trhgd-character-v17`. No new classes, races, world systems, combat engine, XP button or save writer. GAME-128/#118, GAME-123/#101 and the full character programme#82 remain open. Actual publication/merge status is recorded in [PR#121](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/121).

Verified Windows implementation/QA source: `e54ffb48c42ceeb0dd172ffd0579db4d5afd9f68`. Rules pin: `020acf6f873824308cbbed4755b5a1d4a55a470c96deb5561eb7b09823e2c1d0`. Later delivery/coverage/screenshot commits contain documentation only, excluded by both export presets; verify their diff against this exact source before merge. v1–v16 bytes and manifest pins are unchanged; existing campaigns retain their original rules and identities. Fresh games use v17 without an opt-in.

## Playable Windows package

[Download the complete Windows x64 game](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39011007307/artifacts/12093227332). Native workflow: [39011007307](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39011007307).

Inner archive: `game130-spell-repertoires-windows-x64.zip`. SHA-256:

```text
1684cfa0937ff2f844eb0d6ee81466f1b1ee2089ccb6f587180546162a706455
```

1. Download/extract the GitHub artifact ZIP.
2. Extract the inner playable ZIP too. Keep every support file and directory together.
3. Run `road-has-gone-dark.exe`. No installed Godot or Node is required. Escape skips the introduction.
4. New Game → world → origin → hometown → create Wizard/Cleric/martial companion. Old pinned campaigns deliberately do not acquire the new spells.
5. Earn XP through ordinary opportunities; return home and commit advancement manually. Effective caster levels7/9/11/13 unlock tiers4/5/6/7. Meet each actual INT or WIS requirement shown beside the spell. Newly unlocked slots require an eligible rest; the selector grants no resources.
6. Character Sheet → Spellbook → search a name or `tier 4` → set copies → Save spell selections at home. Preparing preserves spent shared slots. An expedition return/rest recovers slots/copies.
7. In battle choose the spell and a highlighted legal target. Hover the action for full costs/effect/duration. Return to breath can select a displayed downed ally only on an unoccupied tile while battle is active. Exit/relaunch to review exact saved characters and combat state.

The archive passed independent CRC/path/duplicate checks, AMD64 game/helper inspection, exact manifest/content/provenance checks and executable hash verification. The native harness runs the bundled game with empty PATH and no source-helper override, checks cold restart, then separately starts the shipped production executable. The diagnostic executable is removed before packaging. All artwork, helper dependencies and existing licence notices are bundled.

## Repertoire

Every new spell uses one main action, one matching class/tier slot and one prepared copy. Range6 and line of sight remain existing tactical authority; radius spells affect the selected target's team only. Requirements are INT/WIS14–17 by actual descriptor. Saves use10+tier+casting modifier+existing save-DC modifiers; existing resistance/evasion semantics remain authoritative. These are original bounded tactical adaptations, not copied sourcebook spell prose or a complete SRD implementation.

|Class|Tier|Spell|Observable distinction|
|---|---:|---|---|
|Wizard|4|Gravitic snare|Reflex negates radius1 immobilisation for two target activations; no damage.|
|Wizard|5|Unravel enchantment|Will negates removal of14 listed temporary boons; no damage or hostile cleansing.|
|Wizard|6|Veil of the company|Radius1 allied50% weapon concealment for two global round boundaries.|
|Wizard|7|Dissonant seal|Will negates spell suppression for two target activations; weapon, psychic and supernatural actions remain legal.|
|Wizard|7|Prismatic volley|Separate fire/Reflex and electricity/Fortitude packets, each3d6+casterlevel/2; separate half saves and resistances.|
|Cleric|4|Path of freedom|Clear seven movement conditions and prevent their reapplication for three global round boundaries.|
|Cleric|5|Litany of resolve|Living ally carries a radius2 dynamic attack/damage+2 insight aura for three global round boundaries.|
|Cleric|6|Purifying renewal|Heal8+effective Cleric level and clear16 listed tactical afflictions; no resources restored.|
|Cleric|6|Elemental covenant|Radius1 allied fire/cold/electricity resistance8 per packet for three global round boundaries.|
|Cleric|7|Return to breath|Heal12+effective Cleric level; recover an unoccupied downed persistent ally tile while battle remains active, without extra turns.|

Before→after class references at tiers4/5/6/7: Wizard4/2/2/2→5/3/3/4; Cleric2/2/2/2→3/3/4/3. Original templates remain; the audit identifies scaled damage/slow and healing/ward repeats rather than treating each reference as a new mechanic. Whole-pack named spell identities143→153; class references198→208. Ten new choices does not mean ten new effect opcodes or ten unprecedented mechanic families across other classes.

Unchanged programme counts:32 base tracks(cap20),18 prestige paths(definition caps3/5/10),37 ancestry families,50 heritages,82 feats,14 skills,45 psychic power identities,14 creatures,15 body forms,228 scheduled career-choice groups. No class/ancestry research occurrence is newly promoted by adding spells. All760 source occurrences/720 taxonomy rows are retained.

## Actual Windows results

|Native phase|Checks|Failures|
|---|---:|---:|
|combat-input|5|0|
|connected/proof.json|37|0|
|connected/restart-proof.json|54|0|
|mechanics/proof.json|592|0|
|mechanics/restart-proof.json|31|0|
|legacy/proof.json|818|0|
|legacy/restart-proof.json|4|0|
|journey/proof.json|497|0|
|journey/restart-proof.json|8|0|
|Actual Godot capture assertions|20|0|

Three actual Wizard/Cleric/Fighter characters each earn360XP through36 completed ordinary objectives, explicitly advance to7 and cast the new tier4 spells. A separate verification fork uses the sole production save writer to cast both spells during an actual saved encounter, restart mid-battle, check spent resources and exact next command/log/RNG, resolve with only the ordinary victory reward, reject duplicates and return/rest. If peaceful history has removed hostile opportunities, the untouched original Old Road lead is used; no occupation is rerolled or resurrected.

Upper-tier Wizard20/Cleric20 and Wizard8/Cleric7/MysticTheurge5 are legal development fixtures, not earned level20 campaigns. The hybrid has effective Wizard13/Cleric12 and independently meets actual casting attributes; the five-level Theurge cap is preserved. Known/prepared access, negative scores/selection, exhausted copies/shared slots/main actions, real saves, targeting, control, immunity, mitigation, aura range, recovery and exact persisted state are tested. Historical v16 competence/skill/restart checks remain pinned. Inherited current-head Windows rules/UI/foundation check URLs are linked by PR#121; no successful older commit is described as fresh current-head testing.

[Raw native distribution receipt](evidence/native-distribution-proof.json), [independent archive audit](evidence/native-archive-audit.json), [testing steps](TESTING.md), [Godot renders](SCREENSHOTS.md), [before/after inventory](REPERTOIRE.json), [remaining gaps](REMAINING-GAPS.md). Initial Windows run39010068218 is explicitly retained as earlier successful evidence; the final run above adds the connected-campaign and earned combat-render acceptance phases.

## Limits and next step

The full character programme is not complete. Dispel/cleanse lists are explicit and bounded; there is no general curse removal, permanent resurrection, spell-resistance system, terrain wall engine or new enemy AI. Current raider AI primarily uses weapons, so caster suppression/hostile boon matchups also use controlled fixtures. Other casters and tiers8–9 remain thin; human per-option acceptance is pending. Recommend the next bounded GAME-128 cohort audit Sorcerer/Druid tiers4–7, preserving their spontaneous/form/creature identities. Do not begin it inside this PR.
