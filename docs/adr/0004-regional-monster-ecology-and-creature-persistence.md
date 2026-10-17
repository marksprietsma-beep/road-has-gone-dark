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

## Interfaces and unresolved questions

**Do not implement** a global ecological scheduler, species breeding cycles, predator/prey differential equations, universal numeric population targets or per-creature AI from this decision alone. Specific population units, conservation rules, habitat generation, migration triggers, alert timing, encounter weighting, creature group IDs, offscreen update cadence, save schemas, species mechanics, ethical choices, taming and battle AI are unresolved.

The eventual solution must build upon one existing combat/rules authority, the player-character pack's immutable versions, world-grounded Site IDs and the campaign's sole save writer. [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition) owns the living-bestiary programme, [GAME-135](https://linear.app/marksprietsma/issue/GAME-135/npc-and-monster-design-grill-ecology-agency-and-encounters) the focused design interview; [GAME-122](https://linear.app/marksprietsma/issue/GAME-122/expand-procedural-combat-encounters-beyond-repetitive-bandits) and GAME-96 own eventual encounter integration. No new combat/monster/NPC gameplay is implemented in this ADR, and the user has deferred hands-on Windows testing until an actual gameplay vertical slice exists.

**Next design dependency:** how distinct creature biology, supernatural powers and NPC class mechanics should share (or diverge from) the existing d20 character, effects and tactical-combat rules.
