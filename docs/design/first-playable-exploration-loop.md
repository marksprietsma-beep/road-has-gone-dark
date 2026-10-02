# GAME-17 — First playable world exploration loop

**Status:** Design proposal for Mark's review, **not** an implementation directive.  
**Date:** 2 October 2026  
**Dependencies:** GAME-11/12 generation and viewer, GAME-28/30/31 atlas artwork and GAME-22 inspector are complete. GAME-7/8/9/10, GAME-19/20/21 and GAME-29 are not complete.

## 1. Player experience — proposed direction

**A small, player-managed travelling party** exploring a broken medieval-fantasy world where fortifications and patrolled roads keep civilisation alive, but dark-magic wilderness is dangerous. **The party** is the primary thing the player controls, not a state or kingdom. This leaves room for a later independent/adventurers' guild charter, guild membership, recruitment, contracts and protection services without requiring a guild-management simulation immediately.

The core promise: **safe haven → choose a reason to travel → take a road or risk the wilds → encounter a threat or discovery → return, resolve consequences and prepare the next excursion**. A location remains recognisable and its discoveries/rewards/consequences persist rather than rerolling on revisit.

This is a **proposal**, not confirmation that Mark has chosen party-centric gameplay as opposed to a guild-management-first perspective.

## 2. Smallest playable sequence (15–25 minutes)

1. **New Game / world seed:** use a deterministic existing generated world, with stable game save ID and starting-location selection. For the initial test, the known fixture world is sufficient; do not regenerate Azgaar merely because an encounter occurs.
2. **Choose or create starting party:** propose **three to five** adventurers with freely chosen race/class roles. The first slice can use simple selectable templates or prefilled names/stats while keeping the roster structure open to full customisation. No mandatory childhood-friends origin until Mark chooses a story start.
3. **Arrive at a fortified settlement:** show the settlement's name, defences, nearby roads and **one offered job** (for example, investigate a reported ruin or missing patrol). Only known/rumoured POI information is displayed. A tiny hamlet's militia/guild protection is context, not a fully simulated roster yet.
4. **Choose a destination and route:** display travel **time**, supplies consumption and indicative **danger**. Following patrolled roads is typically longer but less dangerous than cutting across wilderness; never treat roads as perfectly safe or the wild as impassable.
5. **Travel by advancing world time:** move the party along the selected route, spend rations/time, evaluate one encounter or local discovery. First version uses a concise event with 2–3 outcomes/choices (avoid, negotiate, fight/retreat), **not** a tactical combat system.
6. **Arrive and inspect:** record visited site, outcome, clues and rewards/injuries. A site that was only rumoured becomes discovered when justified; do not reveal every objective marker simply because the world JSON contains it.
7. **Return or continue:** report the job in town and update money, supplies, wounded party members, reputation, discovery journal and permanent location status.
8. **Save / reload and revisit:** the same party and NPC/contract/site identities, outcome and discovered clues survive. No silent reroll on re-entering the town or clicking a place.

### Example of one end-to-end playthrough

A small party begins in a defended market town. The watch offers payment to investigate an old ruin near an abandoned watch road. The player can follow a maintained road and loop south, or take a shortcut through a haunted forest. A deterministic night encounter costs supplies or creates an injury. Reaching the ruin reveals its site record and a clue. Returning to town completes the job and persists the outcome. Visiting the ruin again shows **investigated**, not an entirely new random ruin. Guilds may later supply scouts/temporary escorts for the same kind of job.

## 3. Interaction / user-facing screens

The current `world_fixture_viewer.tscn` is **developer-only QA**, and must not be repurposed as the shipped New Game/map UI. Build distinct game presentation from reused renderer/data components.

| Screen | Minimum v1 | Deferred |
| --- | --- | --- |
| New Game | seed, start settlement, lightweight party setup | complex origin events, full classes/races/portraits |
| Strategic world | discovered geography, known towns/roads/major sites, select destination | omniscient political/marker display, dense debug panels |
| Settlement | name, defences/road context, job offer, rest, supplies | Settlemaker interiors, full commerce, complete NPC roster |
| Travel | route choice, ETA, risk, time progress, 1 event choice | tactical navigation, fully animated units |
| Site / journal | investigate or interact, discoveries and persistent status | full DungeonGen interiors, quests for all 36 marker types |
| Save/load | party+knowledge+visited/outcomes preserved | dynamic simulated world economy |

UI must focus on **the current choice and its consequences**, with the map artwork already accepted as the visual foundation.

## 4. GameWorld contracts needed next (GAME-7, not implemented here)

- `world_ref`: immutable world seed, Azgaar version/schema and stable source IDs for cell, state, province, burg, macro POI; no world entity identity derived only from editable name.
- `party`: player-controlled roster with persistent character IDs, base stats/roles, health/conditions, wages/supplies/inventory and location or current journey.
- `game_clock`: deterministic world time and events processed once, not reset on opening UI; carefully defined travel units.
- `knowledge`: separate **objective** world POIs from rumoured/discovered/visited/cleared player knowledge. No renderer access that directly reveals un-discovered sites.
- `journey`: selected start/destination via cell/road graph, path or segment IDs, risk estimate, start/end ticks, resolved encounter outcomes. Route safety refers to road and protection context, not an untested universal constant.
- `site_state`: keyed by stable macro POI identity, initial deterministic baseline plus mutable history (visited, investigated, rewards exhausted, consequences).
- `settlement_state`: stable burg reference and limited job/stock/defence state; later GAME-19 Settlemaker and GAME-29 guild rosters attach lazily via stable IDs. Re-entering a town does not reroll its characters.
- `save_version`: versioned per-save mutable deltas, atomic writes and migrations when schema evolves; encryption optional and **not required** for persistence.

**Crucial:** keep immutable Azgaar geography and procedural starting values separate from player-affected changes. New local sites can later hang off stable world and region IDs from GAME-21; DungeonGen/Settlemaker should never regenerate all interiors on world creation.

## 5. Risks and guardrails

- **Scope inflation:** don't implement full combat, settlements/guilds, economy, party character creator and hidden-site simulation together. Ship a real traversable quest loop before adding detail.
- **Travel authority:** don't equate visual SVG road/rivers with canonical route traversability; use known Azgaar graph/metadata only when verified. Avoid invented exact geographical distances in the MVP.
- **Reveal control:** GAME-22 debug click inspection is a test facility, **not** permission for the player to click any unknown site.
- **Determinism:** encounter outcomes must depend on world seed + stable encounter ID + time/visit sequence, then be committed to save state. Reload must not permit rerolling a resolved event by accident.
- **Settlements:** no global spawning of NPCs, guild rosters, town layouts or dungeons; instantiate lazily when approached, keep persistent IDs and deltas.
- **Readability:** at normal/dense world zoom, keep map-key/glossary and visual decluttering rules, but design game-specific controls instead of shipping DEV LAYERS.
- **Narrative tone:** protect the black-magic road-and-fortress premise. A generated map isn't a quest in itself.

## 6. Suggested implementation order *after design acceptance*

1. **GAME-7** GameWorld contract/adapter and a fixture-backed save/load smoke test, with stable IDs and knowledge separation.
2. **GAME-8** actual player-facing selectable strategic map, only player-known content, small settlement/site panel.
3. **GAME-9** seed, start-region/settlement commitment and initial party setup (full character creation can follow).
4. **GAME-10** initial dangerous-wilderness/faction/hidden site enrichment where required by the playable route.
5. **A future small traversal/job vertical slice:** one road-vs-wilderness choice, travel tick, one encounter, one investigate/report mission, outcome and save/reload. Add an implementation ticket when the gameplay design is approved rather than overloading a design-only issue.
6. **Then:** GAME-21 local-regions/Town Forge, GAME-19 Settlemaker, GAME-20 DungeonGen and GAME-29 guild lifecycle/contract system, each gated by the observed needs of the playable loop.

The above ordering references existing Linear issues; it does not assert that their full backlogs must be completed before **any** playable test—slice scope should stay narrow.

## 7. Decisions for Mark before this design can be accepted

**A. Primary role (the consequential choice)**  
- **A1 (proposed):** directly lead a travelling party. Later join/found a guild and hire allied guilds.  
- **A2:** act as a guild leader, assigning tasks to parties, with direct adventuring secondary.  
- **A3:** hybrid from the first minutes (heavier scope).

**B. Opening**  
- **B1 (proposed):** choose a starting settlement and party, and one of a few variable inciting incidents.  
- **B2:** author a stronger universal opening disaster/flight that constrains the first region.

**C. First encounters**  
- **C1 (proposed):** narrative choices and lightweight deterministic outcomes, tactical combat as a later standalone system.  
- **C2:** begin with full tactical combat (high early cost).

**D. Party roster**  
- **D1 (proposed):** choose 3–5 initial characters, substantial initial race/class freedom; later recruitment largely situational/random.  
- **D2:** begin with only one player-designed character and recruit others during the first job.

**Acceptance for GAME-17 design:** Mark confirms A–D (or alternatives), agrees on a start/end 20-minute test and the first data contract. Only then mark this design Done and implement the adapter in GAME-7.
