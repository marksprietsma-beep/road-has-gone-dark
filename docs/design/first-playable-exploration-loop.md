# GAME-17 — First playable world exploration loop

**Status:** Partial design acceptance: A (party perspective) confirmed, B (world → region/allegiance → vulnerable hometown) chosen in principle, D (three initial adventurers) preferred, and assignment limits/guild progression agreed in principle. C (encounter mechanics) still unresolved. **Not** an implementation directive.  
**Date:** 2 October 2026  
**Dependencies:** GAME-11/12 generation and viewer, GAME-28/30/31 atlas artwork and GAME-22 inspector are complete. GAME-7/8/9/10, GAME-19/20/21 and GAME-29 are not complete.

## 1. Player experience — proposed direction

**Confirmed player perspective:** direct control of a travelling adventuring party exploring a broken medieval-fantasy world where fortifications and patrolled roads keep civilisation alive. The player customises the adventurers, begins with **three** companions (provisional initial count selected by Mark), and may recruit more. Guild membership and founding are later opportunities **within the same save**, not a mandatory guild-management start.

The core promise: **safe haven → choose a reason to travel → take a road or risk the wilds → encounter a threat or discovery → return, resolve consequences and prepare the next excursion**. A location remains recognisable and its discoveries/rewards/consequences persist rather than rerolling on revisit.

**Confirmed guild progression intent:** Joining an established guild is the natural, easier early route (contracts, training, reputation, limited protection and existing infrastructure), but the player is not forced to join before becoming independent. Founding a new guild is possible from early play **in principle**, yet deliberately expensive, risky and slow: premises/charter or recognition, upkeep, recruitment, relationships, security and trust have to be earned. An independent guild grows into multi-party contracts and hires later; it is not a free starting upgrade.

## 2. Smallest playable sequence (15–25 minutes)

1. **New Game / world selection:** generate/preview/reroll a random world seed, enter an explicit seed, or browse existing generated world templates. In a chosen world select a region/political allegiance, then a suitable small frontier home settlement. Keep seed/version, world identity and starting region/town IDs distinct from a save slot; preview/reroll must never overwrite committed saved games or existing world templates. Use the known fixture for first implementation if necessary.
2. **Choose or create starting party:** **three starting adventurers** (initial preferred count, not a permanent party-size cap), directly customisable in race/class and identity. The first slice may use prefilled templates for faster testing but the model must permit freedom of customisation and later recruitment. No mandatory childhood-friends origin until Mark chooses a story start.
3. **Start in a vulnerable hometown:** the selected **small** hamlet/village is usually too small to host an established guild. Its survival depends on a local militia, defensible roads, a fortified neighbour, external patrons or nearby guild patrols. Show a truthful indication of local protection, roads and nearby threats, and one modest incident/job (e.g., investigate missing patrol supplies), with minimum/maximum adventurer slots. The region is the principal choice; no forced long-term loyalty to the hometown and no invented guild NPCs before GAME-29.
4. **Choose a destination and route:** display travel **time**, supplies consumption and indicative **danger**. Following patrolled roads is typically longer but less dangerous than cutting across wilderness; never treat roads as perfectly safe or the wild as impassable.
5. **Travel by advancing world time:** move the party along the selected route, spend rations/time, evaluate one encounter or local discovery. First version uses a concise event with 2–3 outcomes/choices (avoid, negotiate, fight/retreat), **not** a tactical combat system.
6. **Arrive and inspect:** record visited site, outcome, clues and rewards/injuries. A site that was only rumoured becomes discovered when justified; do not reveal every objective marker simply because the world JSON contains it.
7. **Return or continue:** report the job in town and update money, supplies, wounded party members, reputation, discovery journal and permanent location status.
8. **Save / reload and revisit:** the same party and NPC/contract/site identities, outcome and discovered clues survive. No silent reroll on re-entering the town or clicking a place.

### Example of one end-to-end playthrough

A party of three begins in a **small frontier village**, whose trade and security depend on a larger fortified settlement nearby. A local watch volunteer asks them to investigate a missing supply convoy or an old ruin beside an abandoned road. The player can follow a patrolled route and loop south, or take a shortcut through a haunted forest. A deterministic night encounter costs supplies or creates an injury. Reaching the ruin reveals its site record and a clue. Returning to town completes the job and persists the outcome. Visiting the ruin again shows **investigated**, not an entirely new random ruin. Guilds may later supply scouts/temporary escorts for the same kind of job.

## 2B. New-world browsing, region selection and vulnerable hometown (direction accepted)

**World choice is a separate step from starting a game save.** New Game supports:

1. **Generate random world** — generate once from a displayed seed, preview atlas and candidate frontier regions, and press **Reroll world** as often as desired. Cache recent preview worlds if useful. The previous preview is discarded only from temporary preview state, not from saves. Reroll explicitly changes world identity; it must not silently reroll selected town or characters while editing later steps.
2. **Enter a seed** — reproduce a specific generated world, with the same pinned Azgaar version/recipe; seed alone is insufficient across generator upgrades.
3. **Choose an existing world** — open a previously generated/saved reusable *world template* to create a **separate new playthrough**. Never continue or mutate an existing playthrough just by choosing that world. If a future world-sharing option is provided, distinguish importing an immutable world snapshot from loading a mutable character save.

### Region before hometown

The player can examine map geography, **Azgaar states and provinces**, nearby roads/fortresses, culture/religion context and biome/danger indicators where genuinely available. The player can choose a *political affiliation/state* intentionally or ask for a random region. An actual named faction allegiance (beyond Azgaar states) awaits verified faction data and GAME-10; do not offer fabricated political factions or automatically conflate state, ethnicity, guild and religion.

After a region is chosen, present a **small shortlist** of eligible frontier settlements, with optional random choice. Candidate heuristics for design—not yet proven against the pinned generated world schema—should favour:

- **Small existing burg**, realistically a hamlet/village; little professional protection and ordinarily no permanent full guild hall.
- A reachable **larger, preferably fortified and patrolled** settlement, trade route or defensive patron; not a guaranteed magical safety radius. Protection ties must be explicitly verifiable once GAME-29 adds guild/settlement state.
- Some threat/isolation and travel prospects nearby, avoiding trivially safe capitals and completely inaccessible dead-ends for the default opening.
- Enough nearby known roads/rumours/jobs for one **playable** first excursion; do not automatically reveal all hidden Azgaar markers.

Small hometowns may be described initially with qualitative 'dependent on outside protection' **only when backed by actual available map facts**. They may have committed militia or alliances, but do not invent generated guild NPCs before those systems exist. The party has a chance to assist the home watch, deliver supplies, repair defences, form friends or earn reputation. Future world simulation can worsen or destroy the home if credible threats are ignored, but never punish the player for simply taking a different quest.

**Hometown attachment without forced loyalty:** store a stable `home_burg_id`, initial friendly contacts, limited goodwill/reputation and memories/events as persistent state; grant ordinary social benefits, local jobs and tangible consequences. **No compulsory stay-near-home timer, no unavoidable loyalty quest, and no automatic failure** if the player relocates or joins a distant guild. An independent new guild may choose to establish its headquarters there later, but that is an optional progression, not an opening requirement.

### Technical and UX boundaries for GAME-7/8/9/10

- One world template (immutable `world_id + seed + generator/version/hash`) supports multiple independent per-playthrough save IDs. Reopening an existing world is **not** continuing an existing save.
- Committed `origin` stores `state_id`, optional `province_id`, stable `home_burg_id`, initial party/contacts and only player-known facts. The world map may offer an intentional *pre-game overview* with a different reveal policy from fogged, player-known **in-game** geography; avoid accidental omniscience in actual play.
- Candidate ranking and presence/absence of road adjacency, defensive works, and path reachability require validated Azgaar metadata. No hardcoded distance threshold, militia/guild guarantee or invented 3–5 suitable villages per state. If no candidates, offer a transparent neighbouring-region alternative or allow reselection.
- Selecting a faction/state may influence initial cultural ties, permissions, economic opportunities and relations once supported, **without making alliance mandatory** or silently revealing diplomatic secrets.
- Deterministic derived town details must depend on `world_id` and **stable burg IDs**; preview order, town display names and number of rerolls must not affect NPC/site identity. Mutable local relationships and settlement damage persist per save.
- **GAME-9** owns world/region/home selection UI; **GAME-7** owns identity and persisted origin contract; **GAME-8** supplies the selectable player-facing map; **GAME-10** owns proper people/faction affiliation and hidden knowledge; **GAME-29** later supplies guild protection and hometown politics.

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
| New Game | random seed and reroll, explicit seed, existing-world browser; state/province/region preview and eligible vulnerable hometown; three-character setup | full origin events, world-library sharing, advanced faction relationships, rich full classes/races/portraits |
| Strategic world | discovered geography, known towns/roads/major sites, select destination | omniscient political/marker display, dense debug panels |
| Settlement | name, defences/road context, job offer, rest, supplies | Settlemaker interiors, full commerce, complete NPC roster |
| Travel | route choice, ETA, risk, time progress, 1 event choice | tactical navigation, fully animated units |
| Site / journal | investigate or interact, discoveries and persistent status | full DungeonGen interiors, quests for all 36 marker types |
| Save/load | party+knowledge+visited/outcomes preserved | dynamic simulated world economy |

UI must focus on **the current choice and its consequences**, with the map artwork already accepted as the visual foundation.

## 4. GameWorld contracts needed next (GAME-7, not implemented here)

- `world_ref`: immutable world seed, generation version/recipe, world template identity/fingerprint, and stable source IDs for cell, state, province, burg, macro POI; no world identity derived only from editable names. Several independent game saves may reference the same generated world template, each with its own mutable changes. A new random-preview seed must not overwrite either saved world templates or game saves.
- `origin`: chosen state/province or future political faction affiliation, starting burg ID and optional home relationships. State/culture/province is what Azgaar currently provides; **do not equate those automatically with future guild factions** until GAME-10. A random start still resolves to stable IDs and stores the exact committed choice.
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
- **Settlements:** no global spawning of NPCs, guild rosters, town layouts or dungeons; instantiate lazily when approached, keep persistent IDs and deltas. Small hometowns should use real burg size and verifiable access to roads/fortified protectors. Militia, protection pledges or guild patrols must be generated in the later protection system rather than fabricated from map appearance. If a selected region lacks eligible frontier homes, offer a clear fallback to the nearest eligible region, let the user change region, or flag the constraint—do not invent a settlement.
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

**B. Opening — DIRECTION CONFIRMED**  
Choose (i) a random rerollable seed, manual seed, or existing generated world; (ii) a preferred region/state/province/political affiliation where supported; and (iii) a **small vulnerable home village/hamlet** in that region, preferably near stronger protection. The **region** is the main geographic choice, not exact town optimisation. Hometown loyalty is emergent, never mandatory. Inciting incidents may vary by local conditions; no universal forced catastrophe. Remaining details—exact protection-distance rules, number of candidates, and how existing-world browsing works—are design parameters, not final thresholds.

**C. First encounters**  
- **C1 (proposed):** narrative choices and lightweight deterministic outcomes, tactical combat as a later standalone system.  
- **C2:** begin with full tactical combat (high early cost).

**D. Party and contract capacity — AGREED IN PRINCIPLE**  
Initial travelling party of **three**, individually customisable; later recruit a larger roster. **Per-job and per-POI hard participation limits**, independent of roster size, rather than sending everyone to every activity. Exact limits are balancing parameters, not final gameplay rules. A normal travelling formation of up to ~six adventurers is a **working proposal**, not an approved universal limit; exceptional defences/multisquad operations may be larger. Small-team restrictions may reflect space, concealment, escort capacity or logistics. See the assignment-capacity table below.

**Acceptance for GAME-17 design:** A and the frontier-home opening direction B have been chosen; three initial adventurers and contract participation caps are agreed in principle. Mark still needs to choose **C** encounter/combat resolution and review the first 20-minute experience and exact eligibility rules. Only then mark the design Done and begin GAME-7 implementation.
