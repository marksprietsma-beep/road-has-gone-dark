# Model monsters as living regional ecology with persistent significant individuals

**Status:** Accepted — 17 October 2026 (NPC & Monster Question 1, option B). This is **design direction**, not an implementation authorisation.

**Decision:** Monster species are geographically situated inhabitants of the world, not interchangeable encounter tokens. Habitat, territory, creature-group abundance and pressures, and meaningful relationships with other creatures, people and settlements can change across a Playthrough. Represent ordinary creatures through **bounded regional or local population groups**, while uniquely important or consequential monsters remain **persistent individuals**.

## Why

The Road Has Gone Dark is a replayable fantasy world where exploration and adventuring have intelligible consequences. A wolf population should be relevant to its forest; a troll controlling a bridge may remain a specific threat, potentially moving or surviving between visits. A clearing of hostile animals can affect local risk and resources, and a change in prey, territorial competition, settlement expansion, magical corruption or predation may generate credible later events. These effects must be grounded in recorded state; it is not appropriate to automatically declare that every wolf kill increases deer or spawns a troll.

Treat fauna and monsters as **inhabitants of established geography and fiction**, whether mundane or supernatural. Starting habitats and plausible baseline distribution can be derived from World Template facts such as biome, terrain, water, caves, site type, regional history and settlement influence. A Playthrough records significant subsequent changes (group depletion, movement, growth, new activity, altered threat and persistent important creatures) **without changing the immutable World Template**.

## Bounded population-group representation

- **Aggregate the ordinary:** track relevant species or pack/group conditions at meaningful geographic anchors and abstraction levels, rather than creating personal simulation records for every wolf, spider, deer or raider's animal.
- **Regional dynamics, not automatic respawn:** depletion, return, migration, spreading territory and environmental pressures are *possible grounded changes*. A fully resolved lair or killed specific monster cannot silently reset when a player revisits the same saved Site.
- **Different ecological roles:** habitat suitability, prey/predator relationships, food or resource pressure, territorial overlap, predation on travellers/livestock and competing settlements/factions may influence opportunities and consequences where context supports them. No requirement to model a complete food web.
- **Consequential situations only:** enact developments through the existing bounded World Situation/World Event contract from [ADR 0002](0002-bounded-offscreen-world-simulation.md). Routine unseen populations need not advance on every elapsed tick. Significant faraway events can matter when justified, but neither every creature nor every region is an always-on simulation.
- **Truth and information remain distinct:** rumours, tracks, local testimony and exploration may reveal partial or outdated information about creature movement and threats, respecting Player Knowledge, delayed communications and fair warning when personally significant interests are endangered.

## Significant individual creatures

A unique, recognised or especially consequential animal/monster is a **Significant Creature** with an independently durable identity. Examples include a named predator that survives a fight, a recurrent intelligent troll, a bonded beast, a guardian of a specific ruin or a creature whose actions create a sustained World Situation. Such an individual can acquire persistent injuries, location and history, and may be captured, relocated, driven off, befriended or killed through legitimate gameplay. Its identity and prior encounters cannot be regenerated away because the player returns later or the encounter generator is rerun.

**Significance can emerge dynamically** from ordinary populations. This follows the accepted dynamic-significance principle of [ADR 0002](0002-bounded-offscreen-world-simulation.md): promote a creature when there is a genuine consequential reason, preserving already established facts without inventing a retroactive personal history. Intelligent monster personality and independent choices are governed by the existing bounded significant-NPC principles when applicable; animal instincts and predatory behaviour need not be anthropomorphised.

A significant creature is not automatically an NPC recruit, a guaranteed quest giver or a world boss. Its mechanical body, tactical behaviour, threat fairness and handling of nonhostile outcomes remain separate design decisions.

## Alternatives not selected

- **Encounter-only generation (A):** biome-based disposable encounters with only battle results saved would not support meaningful ecological history, regional cause and effect or recognisable returning creatures.
- **High-granularity persistence (C):** continuously tracked membership, wounds, routines and travel for most packs and specimens would create disproportionate complexity and QA costs, contrary to the bounded simulation decision. Important specific packs may still be explicitly tracked when a World Situation justifies it.

## Distinct species mechanics on shared d20 authority — accepted 17 October 2026 (NPC & Monster Q2, B)

**Creatures must be mechanically distinct where their biology or supernatural nature warrants it**, while resolving their actions and consequences through the **same canonical d20 rules, RulesCharacter/RulesEffects and TacticalCombat authority used by adventurers and humanoid NPCs**. Distinctive species identity is not achieved by relabelling a human Fighter or changing only damage, HP and portrait.

A Creature Species can have relevant **anatomy/body plan and size, natural weapons and attack modes, movement (including climbing, flight or other justified locomotion), senses and perception constraints, innate physical or magical powers, damage-type resistances and vulnerabilities, defences/immunities, and context-sensitive tactics**. Only include capabilities that the established rules engine can evaluate legally; when a movement type or sense is not yet represented, record it as an unimplemented dependency rather than falsely claiming a tested feature. Biological or supernatural traits need not be derived from humanoid equipment/class progression; humanoid or intelligent monsters may additionally learn classes, skills, feats and spellcasting under the shared mechanics where justified.

Examples express **distinct intended gameplay**, not an assertion that the current build already supports them:
- **Giant spider:** a nonhumanoid body and natural bite, with climbing, webbing/immobilisation and ambush behaviours when the corresponding movement/terrain/status rules exist.
- **Troll:** distinctive size, reach and regenerative survival, including mechanically relevant weaknesses or counterplay where supported rather than inflated HP alone.
- **Spectral guardian:** unusual physical interaction, senses, movement and vulnerabilities or resistances, with clear ways a party can understand and oppose it.

Species mechanics and tactics must interact with player spells, feats, equipment, armour, damage and other already-authored character abilities; they should create actual meaningful differences in what the player chooses to do. Their effects, action costs, duration, saves, targeting, resistances, state and RNG belong to existing deterministic battle/character authorities. No creature-only alternative damage engine, duplicate save writer, separate spell economy or unsupported status is authorised.

**Species identity, a particular Significant Creature, and the instance placed into a tactical encounter are different concepts.** Individuals and population groups remain persistent as decided in Q1, while battles may instantiate an appropriate combat actor from those identities without erasing histories or regenerating defeated unique threats. The species definition remains immutable/versioned; injuries, powers learned, affinities, allegiances and outcomes that vary between individuals belong to Playthrough state.

**Rejected:** (A) generic stat blocks with primarily cosmetic species differences; (C) requiring fully simulated organs, separately damageable limbs, anatomical medical systems or detailed metabolism for every creature. Carefully authored exceptional boss mechanics are not forbidden by rejecting mandatory universal physiology.

**Still open:** exact monster stat/progression schema, source and legality of innate abilities, natural-attack interactions, level/challenge calibration, reach/size/body-plan implementation, terrain locomotion, senses, immunity stacking, regeneration/counterplay, AI behaviour and combat art. The game currently has limited companion/summon definitions and mostly humanoid bandit opposition; do not report this accepted design as production-complete or attempt the entire bestiary now. No gameplay changes are authorised by Q2 alone.

**Next interview question:** where species occur in the world, balancing biome, terrain, regional history, supernatural influences and cultural/faction geography against wonder, rarity and consistency.

## Ecological, historical and supernatural distribution — accepted 17 October 2026 (NPC & Monster Q3, B)

**Creature presence is a product of local ecology and geography combined with credible fantasy history, supernatural conditions, cultural and factional activity, and migration.** Habitat constraints and food, terrain, shelter or water govern ordinary wildlife and many beasts. Ancient battles, cursed ground, abandoned ruins, magic, planar intrusions, cults, political conflict, established peoples, trade and displaced populations may plausibly explain unusual creatures far from their otherwise expected habitats. **A species can have overlapping explanations**, rather than being mechanically bound to one biome.

Creature Distribution Context should make world regions **recognisably distinctive yet not perfectly predictable**. A forest naturally supports ordinary predators; an old battlefield might support restless dead; a ruined mage's enclave could support unusual magical beings. These are *possible contextual outcomes*, not compulsory spawns whenever terrain or a building label matches. Do not populate a region with world-history facts that the underlying World Template never established: if a special influence is generated, it needs a deterministic, versioned, credible regional/site provenance compatible with the world's facts. A generated history or magical disturbance must not silently change immutable source geography, cultures or pre-existing settlements.

**Rarity and exceptional presence need stronger grounding.** A rare, unique or legendary creature should usually have an explainable location, history, territory, exceptional event or plausible migration route, and may be the subject of discoveries, partial reports, rumours or contradictory accounts. A unique guardian's death is not followed by spawning a replacement with identical identity. Rarity does not make a creature a guaranteed quest boss or mandate omniscient map markers; revealing its presence is a separate Player Knowledge event.

**Migration and change remain bounded.** Creature Population Groups can expand, decline, be displaced or enter newly suitable regions as the result of significant conditions and recorded Playthrough events (e.g. wildfire, changed prey availability, an invasion, clearing a lair, a political conflict or new corruption). Persistent Significant Creatures can move for individually credible reasons. Re-entry to a Site must reconstruct recorded outcomes rather than rerolling away prior ecological changes. No continuous all-region simulation or invented deterministic predator/prey equation is required.

**Rejected alternatives:** (A) biome-plus-level-only allocation, which loses the world's mythology and historical identity; (C) broadly interchangeable monster distributions with only mild environmental weighting, which make regional preparation and lore unreliable. Surprising creatures remain possible **when supported by an intelligible exceptional cause**.

**Player-facing consequence:** research, local rumours, tracking, scouting, relevant knowledge skills and expedition preparation should eventually help parties predict *credible risks and counters*, subject to uncertainty and misleading testimony. The world can surprise players without ignoring evidence or sending arbitrary creatures as difficulty-balancing devices. The exact sources, checks, information presentation and risk levels are separate open questions.

**Still unresolved:** source/lore schemas, historical and supernatural provenance generation, content/licensing boundaries, biome/terrain affinity tables, species distribution weights, migration/event triggers, unusual-creature rarity definitions, the distinction between regionally rare and globally unique, group conservation rules, encounter generation, tactical threat bands and bestiary breadth. This is a design contract, not approval to build a distribution simulator or content catalogue in the current character-content wave.

## Interfaces and unresolved questions

**Do not implement** a global ecological scheduler, species breeding cycles, predator/prey differential equations, universal numeric population targets or per-creature AI from this decision alone. Specific population units, conservation rules, habitat generation, migration triggers, alert timing, encounter weighting, creature group IDs, offscreen update cadence, save schemas, exact species mechanics, ethical choices, taming and battle AI implementation remain unresolved.

The eventual solution must build upon one existing combat/rules authority, the player-character pack's immutable versions, world-grounded Site IDs and the campaign's sole save writer. [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition) owns the living-bestiary programme, [GAME-135](https://linear.app/marksprietsma/issue/GAME-135/npc-and-monster-design-grill-ecology-agency-and-encounters) the focused design interview; [GAME-122](https://linear.app/marksprietsma/issue/GAME-122/expand-procedural-combat-encounters-beyond-repetitive-bandits) and GAME-96 own eventual encounter integration. No new combat/monster/NPC gameplay is implemented in this ADR, and the user has deferred hands-on Windows testing until an actual gameplay vertical slice exists.

**Resolved dependencies (Q2–Q3):** species-native mechanics share the existing d20 character/effect/tactical authority, and monster distribution is constrained by ecology, geography, history, supernatural influences, factions and migration rather than biome alone or near-random spawning. **Next open dependency (Q4):** threat scaling relative to party level, regional danger, risk signalling and escape.
