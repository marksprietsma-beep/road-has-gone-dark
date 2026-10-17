# GAME-133 — Windows playtest delivery

Ten original Sorcerer/Druid tier4–7 spells extend immutable v17 into v18. The base is main3ccd089, including GAME-132. Existing campaigns retain their exact original pins; fresh campaigns use18. The full GAME-128 repertoire programme and GAME-123 character milestone remain open.

## Build and evidence

[Exact Windows release workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39047311816) · source `1ac6e6024e46efe30a974cd1b3daeba645294c2c` · [PR#133](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/133). The build artifact is `game133-complete-windows-x64`; the evidence artifact is `game133-native-evidence`. Both belong to that exact source run.

The literal playable-ZIP SHA-256 is supplied in its adjacent `.sha256` file, the native `distribution-proof.json`, and the live PR delivery report. Accept the package only after this run succeeds, the independent archive audit passes, and the current PR Windows checks pass. The draft is not merged before those gates. This document does not label a pending or failed run successful.

Extract the outer GitHub artifact ZIP, then `game133-spell-repertoires-windows-x64.zip`. Run `road-has-gone-dark.exe`, keeping every support folder, helper and licence beside it. No installed Godot or Node is needed. Escape skips the introduction. [Exact human steps](TESTING.md).

v18 content hash: `4b2e469a929fc4baa8136b55cdb595af61d428d90ed28bee8fba3f49e2568cfc`. v1–v17 bytes/pins are guarded. The logical delta is exactly ten abilities, five prepared-copy resources, seven statuses and eight extended casting-tier access features; class/feat/ancestry/equipment definitions and all existing spell records remain unchanged. [Delta](PACK-DELTA.json).

## Executable choices

|Class|Tier|Spell|Purpose|
|---|---:|---|---|
|Sorcerer|4|Crystal reservoir|Nonstacking temporary HP buffer.|
|Sorcerer|5|Crushing doubt|Will-negated weapon attack/Will penalties, two activations.|
|Sorcerer|6|Slipstream veil|Single-ally weapon concealment and stride, two round boundaries.|
|Sorcerer|7|Sundering chord|Separate Fortitude saves against bounded area boon removal.|
|Sorcerer|7|Starfall rupture|Force area damage/Reflex half, with resisted Fortitude-fracture rider.|
|Druid|4|Bramble tether|Reflex-negated precise rooting, two activations.|
|Druid|5|Sap renewal|Healing, bounded cleanse and a separate nonstacking buffer.|
|Druid|6|Packward canopy|Area physical resistance/Fortitude support, including living owned creatures.|
|Druid|6|Predator's rhythm|Real melee reach/stride/weapon damage, including natural attacks.|
|Druid|7|Winter's verdict|Cold area damage/Fortitude half, with resisted rooting.|

Every spell costs one main action and its matching tier slot. Sorcerer requires permanent knowledge/CHA and can reuse a known spell while slots remain; Druid requires prepared copies/WIS. Scores14–17 apply to tiers4–7. Existing effective casting-level/hybrid rules, targeting, saves, resistances, expiry, ownership and campaign writing remain authoritative. No new effect opcode or competing engine is introduced. Temporary HP is visible in the active-character panel and target tooltip.

Sorcerer references at tiers4/5/6/7:2/2/2/2→3/3/3/4. Druid:2/2/2/2→3/3/4/3. Whole-pack named spell identities153→163 and class references208→218; these are not163 distinct effect families. Other counts remain32 base tracks(cap20),18 prestige paths(caps3/5/10),37 ancestry families,50 heritages,82 feats,14 skills,45 psychic identities,14 creatures,15 forms and228 scheduled career-choice groups. No new source-catalogue occurrence is promoted.

## Verification and interpretation

All game execution/exports for this wave are Windows-only. The release run checks all ten spells, success/failure and invalid actions, spending/exhaustion/rest, known/prepared choices, legal level20/hybrid fixtures, exact cold state and next-command/log/RNG, production controls, archived v16 histories, three earned careers, actual saved battle/return, headed Godot renders, empty-PATH production launch and ZIP integrity. Its immutable receipt is the result record; check counts are assertions, not counts of unique abilities.

The earned review target is three real characters at level8/490XP through49 ordinary completed objectives, with no injected XP. Sorcerer tier4 unlocks at8, Druid at7. Source1ac6e60 corrects an erroneous test assumption: existing advancement initialises newly owned pools at capacity; saving spell choices is not a rest. A separately labelled backend fixture uses a real spell cost and the sole runtime/save authority to prove depleted known-spell saves do not refill resources. It does not claim production out-of-combat casting. Actual saved battle costs and return/rest are independent gameplay checks.

Level20 and Sorcerer8/Druid7/MysticTheurge5 histories are lawful development fixtures, not earned20. The hybrid has effective Sorcerer13/Druid12, independent CHA/WIS requirements and separate resources. The legacy five-level Theurge cap is unchanged. Party hold/end-turn inputs let each caster demonstrate its spell before allies kill the low-level authored enemies; this is not AI win-rate or final balance evidence.

Completed earlier-source Windows evidence remains explicitly distinguished: [GAME-126 run39043450056](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39043450056), source618416e, verifies archived15/16 mechanics, options, compatibility and twelve earned journeys; [GAME-130 run39045195610](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39045195610), sourcee67fa20, verifies exact17 mechanics/restart and fresh18 Wizard/Cleric campaigns. Both succeeded. Neither is described as fresh testing of a later commit. PR#133 provides the current Windows oracle/UI/foundation results.

Baseline main run39040710821 failed because its archived option audit loaded default17 while the receipt required16. All native phases had zero failures. The option audit now explicitly loads16, preserving GAME-132 and exact pin checks. Fresh connected-campaign checks use the exact current default manifest pin; archived mechanic checks remain fixed16/17. No check is skipped or weakened.

[Genuine Godot evidence](SCREENSHOTS.md) · [full inventory](REPERTOIRE.json) · [limits/next cohort](REMAINING-GAPS.md). Publication status, exact download URL, checksum and merge SHA are maintained on PR#133 and the final delivery report. No callable Linear connector or credential exists in this session; GitHub mirrors#134/#118/#101 carry the verified status, without claiming direct Linear updates.
