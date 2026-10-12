# GAME-118 — Recognisable playable characters

The blocking [PR81 review](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/81#issuecomment-6117744253) was correct: fresh campaigns used legacy content, expanded content was hidden in Identity, the visible classes remained unfamiliar originals, and narrative roles competed with mechanical choices. Green technical tests did not establish player acceptance.

Reviewed GAME103/104 implementation and delivery, the GAME108/109/110/111 programme mirrors (#84–87), GAME36 capability work (#83), the GAME88 accepted direction/catalogue, and the review. Linear is not callable here; the user's GAME118 brief and GitHub review are authoritative. Neither parent draft #80/#81 is merged.

## Player-facing change

Fresh New Game opens directly on **Race & class**, with seven familiar ancestry families and all eleven familiar core classes. Each class supplies editable ability/skill/equipment/spell recommendations. Narrative roles are behind optional guidance. **Build** contains Attributes, Skills, Feats, Equipment, Spells and Progression. The live sheet explains inherited adjustments, totals, class skills/proficiencies, feat benefits, usable abilities, spell copies/slots, resources and ordered history. A permanent Spellbook selects prepared copies or additional learned spontaneous spells at home.

The score picker now binds the selected attribute explicitly and synchronises every visible allocation. Pending name/origin/profession changes produce a corresponding pending biography and live sheet. Saving no longer rerolls the existing motivation behind that preview.

## Genuine mechanics in this batch

These are original TRHGD adaptations of common fantasy/d20 concepts, not copied sourcebook prose or a claim of complete D&D/PF rules fidelity. GAME32 continues to own derived mechanics and the action contract.

| Class | Working distinctions |
| --- | --- |
| Barbarian | Rest-limited three-round Rage (+2 melee/damage/Fortitude, −2 Defence), fast movement, endurance, later reckless strike |
| Bard | Charisma-based known repertoire, ally-area Inspire Courage with rest-limited performance uses, social/knowledge class skills |
| Cleric | Wisdom-based prepared divine spells, ally-area channel healing, fixed Protection domain |
| Druid | Wisdom-based prepared nature control/healing, woodland domain bond, bear form at class five; no animal-companion option claimed |
| Fighter | Martial/armour/shield proficiencies, Guard, Power Strike, Second Wind, bonus feat selections at class 2/4/6, specialization |
| Monk | Unarmoured Wisdom defence, genuine two-strike unarmed Flurry, Ki step, improving unarmed die, Evasion |
| Paladin | Rest-limited Smite Raider, touch healing, Charisma-based Divine Grace at two, courage, later divine preparation |
| Ranger | Explicit current raider quarry bonus, movement-consuming Aimed Shot, archery/tracking skill support, later prepared nature magic |
| Rogue | Ally-threat Sneak Attack scaling at 1/3/5, broad class skills, Evasion and combat feint |
| Sorcerer | Charisma spontaneous casting with a smaller persistent known repertoire, more shared slots, delayed tier access, fixed arcane bloodline |
| Wizard | Intelligence preparation: individual spell copy counts plus shared tier ceilings, larger learned repertoire, earlier new tiers |

Prepared and spontaneous casting differ in authority, not just labels. Prepared spells consume one prepared copy and one tier slot; an exhausted spell cannot use another spell's remaining slot. Spontaneous spells consume shared slots from their learned repertoire; home preparation cannot erase already learned spells. Costs/requirements are enforced in RulesEffects and targeting/actions in the single TacticalCombat authority. Saves can offer half damage on success; Rogue/Monk Evasion prevents that damage on a successful Reflex save. Area ally effects resolve in stable turn order and spend costs once. Weapon techniques use actual weapon rolls.

Seven ancestry families are Human, Dwarf, Elf, Halfling, Gnome, Half-elf and Half-orc. Ten heritage records include Hill Dwarf, Woodland Elf and Stout Halfling. Adjusted attributes affect HP, attacks, saves, skill budgets and spell requirements. Size, movement, inherited skill bonuses and senses appear on the sheet. Small body profiles scale down; unarmed characters do not carry a blade. Unsupported anatomy/bear artwork uses the existing honest neutral humanoid fallback. Culture stays source-world context, distinct from ancestry.

## Compatibility and boundaries

`trhgd-character-v4` / engine3 is separately pinned. Published v1/v2/v3 data remain byte-identical. New core records include typed prepared-copy choices; new player-party schema3 permits canonical ancestry IDs while the pinned helper still supplies original public world facts. Existing creator namespaces and ready parties never auto-upgrade. Pre-existing generated unfinished parties keep legacy content. Only a genuinely fresh party defaults to v4.

Core XP policy is separately pinned in builder-v2: cumulative `10 × (level−1)²`, making the first actual 10-XP victory fund level two. Older builder-v1 thresholds remain unchanged. No test XP grant is exposed in production. Advancement/preparation reuse CharacterBuilderService, its lock/journal and the one existing campaign store. Preparation preserves shared remaining slots. Existing home return is the rest boundary.

The reviewed TacticalCombat file fingerprint changes because new pinned classes need generic ability/area/weapon-technique wiring. Other V1 guard files and all old board/rules data remain untouched; the frozen combat/RNG and GAME32 oracle are required release gates. Movement, diagonal restrictions, existing action tokens and shared reaction remain unchanged.

**Implemented class progression is 1–6, not a completed 1–20 conversion.** Spell lists, domain/bloodline/quarry choices, equipment and feats are bounded. Current regional opportunities are finite, limiting organically attainable higher XP; level-two acceptance uses a real victory, higher mechanics use explicit development fixtures. No prestige option is offered in the fresh pack. Legacy prestige/kernel content remains installed without claiming full tactical completion. This batch does not complete the 403 ancestry / 66 base / approximately 283 prestige programme.

## Continuation programme

Keep #82 and #83–87 open. Next batches must extend actual playable content and tested player journeys, not replace implementation with the catalogue:

1. Extend these eleven classes beyond six: full spell tiers/repertoires, actual parameterised domain/bloodline/quarry/bonus-feat choices, further signature features, equipment and earned progression evidence.
2. Companion/summon authority and additional ancestry capabilities: inherited flexible choices, bonus feats, conditional resistances/immunities, anatomical/equipment compatibility and acquired overlays. Retain original identity through changes; preserve exact published pins.
3. Remaining 55 base-class concepts in coherent martial/divine/arcane/psionic/occult batches with their real dependencies, then earned prestige batches with prerequisites and ordered hybrid progression.
4. Continue all 403 retained ancestry source occurrences and 283 prestige source occurrences (including deduplication/provenance review). No catalogue entry is marked fully complete merely because this low-level original adaptation exists.

Every batch needs fresh UI availability, meaningful numerical/qualitative abilities, deterministic combat, actual earned advancement, save/reload and native delivery. The research catalogue remains fully accounted for in GAME104 COVERAGE.json; playable delivery counts are reported separately here.
