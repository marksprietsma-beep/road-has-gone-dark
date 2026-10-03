# GAME-17 — First playable world exploration loop

**Status:** Partial design acceptance: A (party perspective) confirmed, D (initial three characters) tentatively selected, job capacities/guild progression agreed in principle; B (opening) and C (encounters) still require review. **Not** an implementation directive.  
**Date:** 2 October 2026  
**Dependencies:** GAME-11/12 generation and viewer, GAME-28/30/31 atlas artwork and GAME-22 inspector are complete. GAME-7/8/9/10, GAME-19/20/21 and GAME-29 are not complete.

## 1. Player experience — proposed direction

**Confirmed player perspective:** direct control of a travelling adventuring party exploring a broken medieval-fantasy world where fortifications and patrolled roads keep civilisation alive. The player customises the adventurers, begins with **three** companions (provisional initial count selected by Mark), and may recruit more. Guild membership and founding are later opportunities **within the same save**, not a mandatory guild-management start.

The core promise: **safe haven → choose a reason to travel → take a road or risk the wilds → encounter a threat or discovery → return, resolve consequences and prepare the next excursion**. A location remains recognisable and its discoveries/rewards/consequences persist rather than rerolling on revisit.

**Confirmed guild progression intent:** Joining an established guild is the natural, easier early route (contracts, training, reputation, limited protection and existing infrastructure), but the player is not forced to join before becoming independent. Founding a new guild is possible from early play **in principle**, yet deliberately expensive, risky and slow: premises/charter or recognition, upkeep, recruitment, relationships, security and trust have to be earned. An independent guild grows into multi-party contracts and hires later; it is not a free starting upgrade.

## 2. Smallest playable sequence (15–25 minutes)

1. **New Game / world seed:** use a deterministic existing generated world, with stable game save ID and starting-location selection. For the initial test, the known fixture world is sufficient; do not regenerate Azgaar merely because an encounter occurs.
2. **Choose or create starting party:** **three starting adventurers** (initial preferred count, not a permanent party-size cap), directly customisable in race/class and identity. The first slice may use prefilled templates for faster testing but the model must permit freedom of customisation and later recruitment. No mandatory childhood-friends origin until Mark chooses a story start.
3. **Arrive at a fortified settlement:** show settlement name, defences, nearby roads and **one offered job** (e.g., investigate a reported ruin or missing patrol). Its contract card displays **minimum and maximum adventurers** and any role/supply requirements. Only known/rumoured POIs appear. Guild presence/protection informs job availability, but an early full guild simulation is deferred.
4. **Choose a destination and route:** display travel **time**, supplies consumption and indicative **danger**. Following patrolled roads is typically longer but less dangerous than cutting across wilderness; never treat roads as perfectly safe or the wild as impassable.
5. **Travel by advancing world time:** move the party along the selected route, spend rations/time, evaluate one encounter or local discovery. First version uses a concise event with 2–3 outcomes/choices (avoid, negotiate, fight/retreat), **not** a tactical combat system.
6. **Arrive and inspect:** record visited site, outcome, clues and rewards/injuries. A site that was only rumoured becomes discovered when justified; do not reveal every objective marker simply because the world JSON contains it.
7. **Return or continue:** report the job in town and update money, supplies, wounded party members, reputation, discovery journal and permanent location status.
8. **Save / reload and revisit:** the same party and NPC/contract/site identities, outcome and discovered clues survive. No silent reroll on re-entering the town or clicking a place.

### Example of one end-to-end playthrough

A small party begins in a defended market town. The watch offers payment to investigate an old ruin near an abandoned watch road. The player can follow a maintained road and loop south, or take a shortcut through a haunted forest. A deterministic night encounter costs supplies or creates an injury. Reaching the ruin reveals its site record and a clue. Returning to town completes the job and persists the outcome. Visiting the ruin again shows **investigated**, not an entirely new random ruin. Guilds may later supply scouts/temporary escorts for the same kind of job.

## 2A. Roster versus active party versus expedition (partially agreed)

There are three distinct capacities, **not one global party-size field**:

| Concept | Meaning | Persisted / limits |
| --- | --- | --- |
| **Character roster** | All companions the player has recruited across a save. | May grow as recruitment/guild capacity permits, with costs, illness, leave, injuries, travel and persistent assignments; no early arbitrary global cap. |
| **Travelling party** | Companions presently travelling with the player. | For first playable slice **three** members; propose allowing expansion toward roughly **six** in ordinary travel, but Mark has not approved six as a final rule. |
| **Assigned expedition team** | Companions participating in a particular contract, location entry or dispatched guild job. | A job/location explicitly declares **hard min/max participants**, plus required skills/gear and available roster/party member checks. |

A contract can also include **recommended team size** as advisory difficulty guidance, distinct from an enforced hard cap. Exceeding a max must never simply ignore the rule or remove adventurers randomly: require the player to choose who participates; remaining members wait at camp, guard the wagon, rest in town or perform other permitted tasks. In later guild progression they may be assigned independent missions. **No auto-creation of extra adventurers** merely because the contract allows more.

### Provisional assignment-size examples (for playtesting, not approved final numbers)

| Job / location | Min | Max | Why / gameplay |
| --- | ---: | ---: | --- |
| Discreet scouting / infiltration | 1 | 2 | Stealth, noise, visibility; a large team is a liability. |
| Small cave / crypt | 1 | 3 | Confined access and limited space, but a solo risk-taker is allowed. |
| Ruin investigation | 2 | 4 | Requires practical support; still dangerous. |
| Caravan escort | 2 | 6 | Guards spread across vehicles and road segments. |
| Road patrol / monster hunt | 3 | 6 | Multiple specialties useful; supplies and coordination cost. |
| Defence of a threatened outpost | 3 | 8 | Local militia/allied detachments may count separately from the direct player party. |

These are **illustrative knobs**. Don't apply a universal max=6 to fort sieges or narrow catacombs. At larger scale, a guild contract may dispatch multiple separately capped squads rather than represent an implausibly huge single party. Major guilds and towns may field support NPCs **outside** the player's party slots, recorded distinctly, not hidden extra party members.

### Contract/location data boundary

Store `min_party_size`, `max_party_size`, `recommended_size` (optional), `required_roles` (optional), `scope` (travelling-party / dispatched squad / multi-party operation) and `participants` by stable character IDs. The job can require an available scout/healer or equipment/transport; requirements must be visibly explained. POI-specific entry limits should be stored with a location **interaction** (e.g. cave passage), not automatically with every map icon class: one cave might take two, another a dozen. These values should be data-driven and consistent across world map, local region, dungeons and guild contracts.

`participants` and `assignments` are per-save mutable state; the generated site's canonical identity and layout are not. Never reselect random job capacity on revisiting a known contract, and account for casualties, recruits, resignations and hired contractors persistently.

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
- `roster`: all persistently recruited adventurers with unique character IDs, class/race roles, health/conditions, availability, membership and current assignment. Recruiting a member must not force them into every expedition; retain who is resting, travelling, hired elsewhere or stationed at a hub.
- `party` / `expedition`: selected **subset** of the roster, distinct from the full roster and later guild membership. Participant count must obey `minimum_slots <= selected_count <= maximum_slots` for a job/POI-specific activity, with independently validated role requirements and situational constraints. No single cap should hard-code roster/guild capacity.
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
- **Assignment capacity:** validate both entry/route constraints and the contract's party-size limits before travel/participation. A large guild roster must not be confused with one expedition. Do not make lower difficulty automatically equal a smaller cap or make larger parties trivialise stealth, supplies or encounters.
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

**A. Primary role — CONFIRMED**  
Directly command and customise an adventuring party; begin with three members (provisional count), expand the roster through recruitment, and potentially lead multiple teams as a guild grows. The player can join an established guild, or attempt the harder, slower route of founding one independently.

**B. Opening**  
- **B1 (proposed):** choose a starting settlement and party, and one of a few variable inciting incidents.  
- **B2:** author a stronger universal opening disaster/flight that constrains the first region.

**C. First encounters**  
- **C1 (proposed):** narrative choices and lightweight deterministic outcomes, tactical combat as a later standalone system.  
- **C2:** begin with full tactical combat (high early cost).

**D. Party and contract capacity — AGREED IN PRINCIPLE**  
Initial travelling party of **three**, individually customisable; later recruit a larger roster. **Per-job and per-POI hard participation limits**, independent of roster size, rather than sending everyone to every activity. Exact limits are balancing parameters, not final gameplay rules. A normal travelling formation of up to ~six adventurers is a **working proposal**, not an approved universal limit; exceptional defences/multisquad operations may be larger. Small-team restrictions may reflect space, concealment, escort capacity or logistics. See the assignment-capacity table below.

**Acceptance for GAME-17 design:** A confirmed; starting three and contract capacities tentatively accepted. Mark still needs to choose **B** opening format and **C** encounter resolution, and review the small vertical slice and contract-size conventions. Only then mark the design Done and begin GAME-7 implementation.
