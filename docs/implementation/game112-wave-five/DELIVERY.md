# Wave Five — first character cohort, Windows acceptance pending

Recovered real implementation is pushed in draft PR [103](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/103), first source commit `9389f00df4415b193da7daac99cd099145963cb5`, on the existing `feature/game-112-character-catalogue-wave-five` branch. Parent main is the Windows-only PR102 merge `129e5de4621b0b662aa8c1999b2407d098e2fe17`; synchronized branch head was3a098d5. No existing content implementation was restarted. Later skill/capture acceptance additions are recorded in the next commit.

v15 candidate pin: `65983a234663928122e7b085af01e4d8246e1b95df67612d7236dc39e14452e1`. All v1–v14 pack bytes and frozen GAME-32 tactical source match HISTORICAL-PINS.json. New campaigns select v15; existing campaigns retain their exact pins. Windows is the only supported target; no Linux CI or Linux review package is introduced.

## Implemented first cohort

- Duskblade1–20: INT-based martial spellcasting, finite tier slots, persistent runic choices and real melee spell channeling from class3. One authoritative equipped/proficient melee attack; only its actual hit delivers the original owned/selected spell through RulesEffects. One main action and one original slot are paid on hits, misses and concealment. No second attack, free spell or HP-loss inference. Critical weapon damage does not double the spell.
- Spirit Shaman1–20: WIS-based bounded retrieved nature/spirit repertoire, nine spell tiers, finite guide abilities and persistent guide choices. Initial choice consumes its permit; existing actual home-return rest permits one change. Selecting spells never refills slots; encounter changes, reopening the sheet and restart do not refresh retrieval. Ordinary spontaneous classes retain their known-spell restrictions.
- Abjurant Champion5 and original Grove Warden3: permanent feat/skill/BAB/casting prerequisites, selected hybrid caster advancement, finite ward/strike or sanctuary/renewal actions. Never starting or automatically awarded. The ordinary campaign earns360XP and explicitly selects Abjurant Champion; a separately saved legal Duskblade decline also reloads exactly.
- Catfolk, Riverborn, Wildborn and Ratfolk original ancestry adaptations; Swiftstrider/Rime additional heritages. Inherited attributes, physical/mental traits, natural attacks or finite protection work; culture/background stay separate. All unusual anatomy has an honest neutral humanoid LPC fallback.
- Sixteen gated feats; thirty-two named spells; ten selectable psychic powers with thirty actual augmentation variants; Ancestor Sentinel/Briar Beast owned creatures and real actions/summons; Moon Stag/Iron Tortoise/Briar Cat forms with physical changes, suppression, reversion and expiry. Existing ownership, turn, duration, action, RNG and save authority is reused.

## Inventory, not milestone acceptance

| Category | Released v14 | v15 candidate |
|---|---:|---:|
| Base classes |30|32|
| Prestige paths |16|18|
| Ancestry families |33|37|
| Heritages |44|50|
| Feats |66|82|
| Skills |14|14|
| Named spell identities |111|143|
| Class spell references |162|198|
| Psychic identities |35|45|
| Other named ability labels |367|401|
| Other ability records |391|425|
| Creatures |12|14|
| Body forms |12|15|
| Scheduled career-choice groups |212|228|
| Channel delivery wrappers (not new spells) |0|10|

REPERTOIRE.json records identities/references. ACTIVE-MECHANICS.json separately excludes unreferenced legacy abilities, passive/automatic records, channel wrappers and psychic augmentation. It folds class gates and numeric progression into conservative structural effect/cost groups: v14 has568candidate active records/307structural groups; v15 has648/364. These are reproducible source groups and upper bounds on distinct design ideas, not proof of364individually native-validated, balanced player choices. Do not equate level labels, different names, scheduled selections or all feature records to unique mechanics. Native receipts remain the playability gate.

## Evidence so far

Development-host source checks:1591mechanics/0;42exact cold snapshot/replay/0; expanded ordinary earned campaign565/0; earned process restart4/0. The latter actually resolves Craft, Survival, Perception, Arcana, Religion, Persuasion and Insight options, verifies actual saved skill totals/seed-stable previews, outcomes, information, rewards and duplicate rejection. Raw examples are in evidence/source-earned-skills.json. Existing opportunity mechanics already support these consequences; no new world/quest system was needed.

Frozen oracle22181/0; migration235/0; migration cold6/0; historical append-only guard9/0. Genuine production Godot renders: creator54checks/0, campaign81/0;36creator and45campaign frames at640×360/1280×720/2560×1440.13selected frames are committed under screenshots. Source runtime matches9389f00; capture harness additions are separate. Rendering used the development host’s actual Godot/OpenGL, not mockups or claimed Windows screenshots. High-level fixtures are explicitly labelled; earned sheets and combat use actual saved campaign checkpoints. The earlier failed capture correctly rejected replacing an earned history; the corrected advanced fixture starts a new normal birth through the original writer, isolated from the earned save.

Current Windows CI: [dedicated Wave Five38839675605](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38839675605). Source phase has passed; native executable acceptance and remaining compatibility are still running. This document does not claim a v15 Windows artifact or merge until actual successful receipts and checksum are added. Wave Four’s known Windows download is retained in its own delivery and does not include v15.

## Testing the eventual Windows package

Extract the downloaded Actions ZIP, then the contained playable ZIP. Keep the entire game directory together and launch road-has-gone-dark.exe; no installed Godot or Node. Start New Game to use v15, choose world/origin/hometown, and review three distinct adventurers. Starting class lists contain base classes only. Select Duskblade/Spirit Shaman and review actual attributes, skills, feats, gear, spell selections and specialisations; save each adventurer and choose Party ready.

Use ordinary contextual adventures to earn XP. At home, review/explicitly commit funded advancement. Duskblade channel actions appear from class3 for selected eligible spells and the equipped melee weapon; review main/slot cost, target/movement highlights, misses and delivered effects. Spirit Shaman’s Spellbook displays its saved retrieval allowance; return from a real expedition/rest before exchanging the repertoire. Exit/relaunch and verify identities, history, known/retrieved spells, resources and XP persist. Inspect prestige requirements; eligibility alone changes nothing and a legal base-class continuation remains available.

## Remaining scope

This coherent first cohort is not the rich-character milestone’s completion. #101 and #82 remain OPEN. The approved near-term guideposts are38–45base careers,25–35prestige,45–55families/60–80heritages,100–150functional feats, broad executable ability variety and meaningful integrated build journeys/human acceptance. The760source occurrences remain the long-term research ledger. Coverage still has79previously native-mapped occurrences/681unresolved until Windows proof permits promoting the eight new bounded mappings. See CONTINUATION.md for exact remaining gates and next content priorities.
