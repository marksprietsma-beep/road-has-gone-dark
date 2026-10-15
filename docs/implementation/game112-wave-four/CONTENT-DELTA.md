# Implemented v14 additions

Bounded original adaptations. Names identify research concepts; this is not a complete sourcebook conversion. The before/after inventory is in REPERTOIRE.json. Levels above ordinary earned campaign evidence are development fixtures.

## Careers

- **Erudite** (`erudite`): A broad learned psychic repertoire constrained by distinct powers per eligible rest: 1 + class level/4. Repeated casts and augmentation share the same power identity. Saved across encounters and reloads; only an eligible rest resets the list. Base track, cap 20.
- **Divine Mind** (`divine-mind`): Armoured psychic support: select a mantle, learn restricted powers and maintain one local aura. Switching auras costs an action and resolve; nearby living allies receive effects only while in range and line of sight. Base track, cap 20.
- **Marshal** (`marshal`): Martial leadership: select command doctrines, maintain an area aura and spend finite command uses on rally or manoeuvre support. No spell or psychic progression. Base track, cap 20.
- **Cognition Adept** (`cognition-adept`): Original adaptation of the researched Slayer concept: earned psychic/martial hunter with precise strikes, mental wards and learned powers. Five playable levels. Prestige track, cap 5.
- **Beguiler** (`beguiler`): An Intelligence-based spontaneous illusion and control caster with broad infiltration skills. Choose a subtle discipline; conceal allies, undermine attacks and restrain enemies with actual saving throws. No mind-controlled AI or trap subsystem is claimed. Base track, cap 20.
- **Dragonfire Adept** (`dragonfire-adept`): A repeatable elemental breath specialist. Breath spends a main action, uses a Reflex save and affects enemies in a radius-one burst around a legal target. Selected invocations spend finite resolve. No cone, flight or friendly-fire mechanics are claimed. Base track, cap 20.
- **War Chanter** (`war-chanter`): Earned battlefield chorus: a wider area doctrine and finite rally, with five deliberate prestige levels. Prestige track, cap 5.
- **Archmage** (`archmage`): Earned high arcana. Deliberately advance an existing arcane class, then select real warding or force mastery. Five prestige levels; no automatic assignment. Prestige track, cap 5.
- **Metamind** (`metamind`): Earned psychic resource mastery. A finite reserve reclaims power points through a main action; learn additional powers and choose disciplined reserve or psychic resilience. Ten prestige levels. Prestige track, cap 10.

## Ancestries and heritages

- **Bugbear** (`heritage-bugbear`): A strong, quick humanoid. Strength +2, Dexterity +2, Charisma −2; initiative +2. Medium size.
- **Ogre** (`heritage-ogre`): A large, powerful humanoid. Strength +4, Intelligence −2, Charisma −2; Fortitude +1 and melee reach +1. Occupies one tactical tile.
- **Half-giant** (`heritage-half-giant`): A massive humanoid with psychic inheritance. Strength +2, Dexterity −2; defence +1 and fire resistance2. Inherited stomp costs one of two points per home rest and leaves one adjacent enemy off balance.
- **Troglodyte** (`heritage-troglodyte`): A resilient reptilian humanoid. Strength +2, Constitution +2, Intelligence −2; natural defence +2. An inherited bite makes an ordinary melee attack for1d8 physical damage.
- **Air Genasi** (`heritage-air-genasi`): Dexterity+2, Intelligence+2, Wisdom−2; electricity resistance3 and a costed burst of speed.
- **Earth Genasi** (`heritage-earth-genasi`): Strength+2, Constitution+2, Charisma−2; physical resistance2, stride−1 and a costed stone ward.
- **Fire Genasi** (`heritage-fire-genasi`): Intelligence+2, Dexterity+2, Charisma−2; fire resistance3 and a costed flame attack.
- **Water Genasi** (`heritage-water-genasi`): Constitution+2, Wisdom+2, Charisma−2; cold resistance3 and a costed healing gift. No aquatic exploration ability.
- **Highwind Genasi** (`heritage-air-genasi-highwind`): An inherited Highwind Genasi variation with its own attribute and defensive/movement tradeoffs. Culture remains independent.
- **Granite Genasi** (`heritage-earth-genasi-granite`): An inherited Granite Genasi variation with its own attribute and defensive/movement tradeoffs. Culture remains independent.

## Feats

- **Iron discipline** (`iron-discipline`): Prerequisites: `{"op":"feat","id":"psychic-discipline"}`. Effects: `[{"modifiers":[{"stat":"will","type":"insight","value":{"op":"const","value":2}}],"abilities":[]}]`.
- **Deep reserve** (`deep-reserve`): Prerequisites: `{"op":"feat","id":"expanded-psychic-reserve"}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"resource_bonuses":{"psychic-points":{"op":"const","value":4}}}}]`.
- **Commanding presence** (`commanding-presence`): Prerequisites: `{"op":"class_level","id":"marshal","min":1}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"resource_bonuses":{"marshal-resolve":{"op":"const","value":2}}}}]`.
- **Steadfast mantle** (`steadfast-mantle`): Prerequisites: `{"op":"class_level","id":"divine-mind","min":1}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"resource_bonuses":{"divine-mind-resolve":{"op":"const","value":2}}}}]`.
- **Bugbear skirmisher** (`bugbear-skirmisher`): Prerequisites: `{"op":"ancestry","id":"bugbear"}`. Effects: `[{"modifiers":[{"stat":"stride","type":"training","value":{"op":"const","value":1}},{"stat":"reflex","type":"training","value":{"op":"const","value":1}}],"abilities":[]}]`.
- **Ogre endurance** (`ogre-endurance`): Prerequisites: `{"op":"ancestry","id":"ogre"}`. Effects: `[{"modifiers":[{"stat":"HP","type":"training","value":{"op":"const","value":4}}],"abilities":[]}]`.
- **Natural ferocity** (`natural-ferocity`): Prerequisites: `{"op":"feature","id":"troglodyte-bite"}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"weapon_damage":{"boar-tusks":"1d10"}}}]`.
- **Bond veteran** (`bond-veteran`): Prerequisites: `{"op":"feat","id":"beast-stewardship"}`. Effects: `[{"modifiers":[{"stat":"fortitude","type":"training","value":{"op":"const","value":2}}],"abilities":[]}]`.
- **Draconic vigor** (`draconic-vigor`): Prerequisites: `{"op":"class_level","id":"dragonfire-adept","min":1}`. Effects: `[{"modifiers":[{"stat":"HP","type":"training","value":{"op":"const","value":4}}],"abilities":[],"capabilities":{"resource_bonuses":{"draconic-resolve":{"op":"const","value":1}}}}]`.
- **Beguiling discipline** (`beguiling-discipline`): Prerequisites: `{"op":"class_level","id":"beguiler","min":3}`. Effects: `[{"modifiers":[{"stat":"save_dc","type":"training","value":{"op":"const","value":1}}],"abilities":[]}]`.
- **Elemental endurance** (`elemental-endurance`): Prerequisites: `{"op":"ancestry","id":"earth-genasi"}`. Effects: `[{"modifiers":[{"stat":"fortitude","type":"insight","value":{"op":"const","value":2}}],"abilities":[]}]`.
- **Highwind footwork** (`highwind-footwork`): Prerequisites: `{"op":"ancestry","id":"air-genasi"}`. Effects: `[{"modifiers":[{"stat":"reflex","type":"insight","value":{"op":"const","value":2}},{"stat":"initiative","type":"training","value":{"op":"const","value":1}}],"abilities":[]}]`.
- **Ember ward** (`ember-ward`): Prerequisites: `{"op":"ancestry","id":"fire-genasi"}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"resistances":{"fire":5}}}]`.
- **Tidal reserve** (`tidal-reserve`): Prerequisites: `{"op":"ancestry","id":"water-genasi"}`. Effects: `[{"modifiers":[],"abilities":[],"capabilities":{"resource_bonuses":{"water-genasi-inheritance":{"op":"const","value":1}}}}]`.
- **Devoted bond** (`devoted-bond`): Prerequisites: `{"op":"feat","id":"beast-stewardship"}`. Effects: `[{"modifiers":[],"abilities":[],"companion_growth":{"op":"const","value":1}}]`.
- **Form reach training** (`form-reach-training`): Prerequisites: `{"op":"feature","id":"druid-shape"}`. Effects: `[{"modifiers":[{"stat":"reach","type":"circumstance","value":{"op":"const","value":1},"when":{"op":"tag","id":"body_transformed"}}],"abilities":[]}]`.

## Learned psychic powers

- **Crystal Shard** (`power-crystal-shard`): Tier1 energy; main action, 1 points, magnitude4. Direct damage.
- **Iron Vigor** (`power-iron-vigor`): Tier1 body; main action, 1 points, magnitude4. Temporary HP.
- **Mental Dampening** (`power-mental-dampening`): Tier2 mind; main action, 3 points, magnitude8. Will negates weakened; augmentation adds damage.
- **Rallying Thought** (`power-rallying-thought`): Tier2 unity; main action, 3 points, magnitude8. Melee/Will+2 for three rounds, plus temporary HP.
- **Adrenal Response** (`power-adrenal-response`): Tier3 body; main action, 5 points, magnitude12. Stride+2 for two rounds plus temporary HP.
- **Synaptic Javelin** (`power-synaptic-javelin`): Tier4 energy; main action, 7 points, magnitude16. Direct damage.
- **Renewing Concord** (`power-renewing-concord`): Tier5 unity; main action, 9 points, magnitude20. Actual healing bounded by maximum HP.
- **Crystalline Prison** (`power-crystalline-prison`): Tier6 mind; main action, 11 points, magnitude24. Will negates immobility and damage.
- **Frost Lance** (`power-frost-lance`): Tier2; main action/3 points, magnitude8. Reflex negates cold damage and slowed.
- **Vigilant Link** (`power-vigilant-link`): Tier2; main action/3 points, magnitude8. Initiative+3/Will+2 and temporary HP.
- **Severing Thought** (`power-severing-thought`): Tier3; main action/5 points, magnitude12. Remove guarding/psychic screen and apply psychic damage.
- **Communal Renewal** (`power-communal-renewal`): Tier4; main action/7 points, magnitude16. Heal selected ally and adjacent allies; bounded by maximum HP.
- **Iron Carapace** (`power-iron-carapace`): Tier5; main action/9 points, magnitude20. Physical resistance4, stride−1 for3 rounds, plus temporary HP.
- **Void Detonation** (`power-void-detonation`): Tier7; main action/13 points, magnitude28. Force burst on the selected enemy and adjacent enemies.

## Owned creatures

- **Thorn guardian** (`thorn-guardian`): Body spirit-biped, large; natural weapon stone-slam. Action definitions use ordinary effort, ownership, initiative and duration.
- **Ember spirit** (`ember-spirit`): Body spirit-biped, small; natural weapon spirit-touch. Action definitions use ordinary effort, ownership, initiative and duration.
- **Frost hound** (`frost-hound`): Body quadruped, medium; natural weapon frost-fangs. Action definitions use ordinary effort, ownership, initiative and duration.
- **Bulwark construct** (`bulwark-construct`): Body heavy-biped, medium; natural weapon bulwark-slam. Action definitions use ordinary effort, ownership, initiative and duration.

## Additional named spell identities

Anchoring ward, Cleansing ward, Collective refuge, Compelling stillness, Crushing apprehension, Dominion of dread, Dread convergence, False openings, Fracture concentration, Lucid refuge, Mass veil, Mind tether, Nightmare pressure, Perfect concealment, Phantasmal assault, Prismatic doubt, Restorative circle, Sanctuary of shadows, Sheltering fiction, Summon Bulwark construct, Summon Frost hound, Unerring poise, Veil of doubt, Veiled step.

Class references are grouped separately; the same named spell in multiple class lists is counted once. These names also include bounded effects and shared higher-tier techniques; they are not a claim of24 new effect opcodes.

## Scope boundaries

Erudite limits distinct power identities, not augmentation variants, between eligible rests. Divine Mind/Marshal/War Chanter project maintained typed auras through the inherited tactical adapter. Beguiler uses actual concealment, saving throws and conditions, without mind-controlled AI. Dragonfire Adept uses enemy-centred bursts, not cones. Metamind uses finite main-action reclamation, not unlimited power-point loops. Archmage advances a chosen existing caster and grants selected force/ward powers.

No custom ancestry art, flight, aquatic exploration, environmental vision, new world content, spell-channeling on a qualifying weapon hit, or rest-retrieved Spirit Shaman repertoire is claimed. Duskblade and Spirit Shaman remain next character-mechanics work. Historicalv1–v13 packs and GAME-32 source are unchanged.
