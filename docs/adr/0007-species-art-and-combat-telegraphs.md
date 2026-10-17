# Recognisable species and truthful, readable tactical presentation

**Status:** Accepted — 17 October 2026, NPC & Monster Question 11 (option B). This is design direction; no new sprite engine or creature art is delivered by this document.

## Decision

Every represented creature species should be visually recognisable **as the species it mechanically is**. Prioritise genuine species silhouettes, anatomy, proportions, scale, skin/material texture and colour, characteristic movement, and appropriate visible weapons or gear when worn. An orc should read as an orc, including plausible green/olive/brown colour variations and distinctive physical traits; a giant spider must not be a recoloured human; a troll should be visibly massive or otherwise identifiable; a spectral guardian should convey its supernatural condition. Presentation does not reduce distinct peoples to rigid stereotypes or erase individual diversity.

A sprite's **species, identity, equipped items and active effects are authoritative inputs**, not cosmetic reinterpretations based on a class nickname or enemy rank. A player's ancestry and heritage, NPC identity, and distinctive monster body plan should remain recognisable in party creation, roster, local exploration and tactical encounters where each view supports art. Appearance options can vary within species and be persistent without secretly altering gameplay attributes.

## Reusable, scope-aware art

- **Humanoid and playable species:** extend the accepted Universal LPC modular body, heads, palettes, stature, facial features, clothing/armour and weapon-layer workflow (GAME-94, GAME-106, GAME-107), respecting per-layer credits, licences, deterministic recipes, pose alignment and directions. Do not create a competing humanoid sprite renderer merely for NPCs.
- **Nonhumanoid body plans:** where LPC fundamentally cannot represent quadrupeds, spiders, giants, winged beings or spectral forms truthfully, introduce small curated, legally usable or newly authored sprite/animation families with **reusable species-specific movement/attack templates** rather than forcing every anatomy into the human skeleton. Reuse the same game-facing combat presentation contract and event state; this is not a second tactics or effects engine.
- **Individuality:** variant palettes, markings, size distinctions, garments, armaments, wear or other lore-consistent traits can visually distinguish significant individuals and groups without obliging extensive bespoke art for every member. Equipment should match mechanically equipped items where appropriate, not arbitrary class costumes. Anatomical constraints remain real (e.g., not all equipment fits every body plan).
- **Honest fallback:** if a species or particular animation has no compatible asset, use a clearly marked temporary icon/silhouette or fallback rather than misrepresenting a nonhumanoid with a humanoid sprite or showing fake gear.

## Readability and action economy

Legible combat requires more than a recognizable idle sprite. Attack direction/range, actions, threatened spaces, harmful surfaces, statuses, selected targets, movement intent, deaths/retreats and known resistances or regeneration effects need **truthful player-facing presentation** in appropriate contexts. Unique powers and eventual boss/lair actions need understandable **telegraphs, timing, readable threat boundaries and opportunities for counterplay** proportional to fair-warning decisions from ADR 0004. Invisible or sudden severe hits must not result simply from omitted UI cues.

Visual effects follow the actual d20 command resolution and status/event log; animations cannot grant free actions, misstate attack ranges, portray spells that cannot be cast or depict damage where the battle recorded none. Avoid revealing genuine unseen enemies, hidden statuses or unknown spells just to improve legibility. Offer non-colour cues (shape, icon, text, sound where useful) so hue variation is not the sole channel for faction, condition or telegraph interpretation.

## Acceptance for a bounded vertical slice

Compare **at least three mechanically different body plans** in the native Windows tactical view, including one recognisable nonhumanoid, plus a visually distinct playable/non-player humanoid ancestry and suitable actual equipment. Demonstrate real walking/attacking/being hit, a species-specific ability or condition, readable target and hazard indicators, and if included, a correctly telegraphed boss/lair action. Require visual consistency after save/cold restart and actual combat events, with screenshots or captured frames. Verify deterministic asset lookup and packaging; keep compatible licensing and attribution.

The initial playable slice need not implement art for every one of the character system's many ancestries or for the complete planned bestiary. Curated modular coverage and honest missing-content labels beat a vast untested art catalogue.

## Existing owners and future work

- [GAME-94](https://linear.app/marksprietsma/issue/GAME-94/lpc-character-presentation-v1-distinctive-adventurers-raiders-native): production LPC humanoid presentation foundation.
- [GAME-106](https://linear.app/marksprietsma/issue/GAME-106/make-lpc-character-sprites-visibly-reflect-playable-ancestry-and): player and humanoid ancestry appearance, including visibly nonhuman orcs.
- [GAME-107](https://linear.app/marksprietsma/issue/GAME-107/show-equipped-weapons-armour-and-gear-on-persistent-lpc): equipment-aware LPC layers.
- [GAME-93](https://linear.app/marksprietsma/issue/GAME-93/tactical-combat-sprite-art-spike-modular-heroes-raiders-and-godot): art evidence and asset provenance.
- [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition): species/NPC programme. [GAME-140](https://linear.app/marksprietsma/issue/GAME-140/distinct-nonhumanoid-monster-sprites-and-truthful-combat-telegraphs) owns bounded **nonhumanoid monster silhouette, animation and ability-telegraph integration**; GAME-106 remains the player/humanoid ancestry owner.
- [GAME-136](https://linear.app/marksprietsma/issue/GAME-136/boss-and-epic-npc-action-economy-lair-actions-and-bounded-off-turn): eventual boss and lair power timings.

**Rejected:** (A) superficial recolours and labels as the primary species distinction; (C) extensive unique bespoke artwork and lengthy individual animation sets for most species as a prerequisite for gameplay.

**Open:** exact initial species list, asset licence selection, silhouette scale/footprint art, modular animation libraries, Godot renderer integration, nonhumanoid layer rigs, VFX mapping, equipment fit and spell/status telegraph thresholds. No gameplay implementation or graphics production is authorised by Question 11 alone.

**Final design interview dependency (Q12):** choose the first integrated gameplay slice and Windows playtest boundary, rather than expanding NPC/monster content indefinitely without playable evidence.
