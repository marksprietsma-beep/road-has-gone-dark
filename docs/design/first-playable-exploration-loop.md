# GAME-17 — First playable world exploration loop

**Status:** Direction accepted in principle: party-led role (A), region-first vulnerable hometown (B), **grid-based manual tactical combat + strong auto-resolve (C)**, three initial adventurers and future deeply extensible class/prestige progression (D). Specific simplification choices, action economy and first-slice content remain **open design details**. This is a design document, not an implementation directive.  
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
5. **Travel by advancing world time:** move the party along the chosen route and consume supplies/time. Encounters offer retreat, negotiation or battle where appropriate. **Battle means a small grid-based tactical encounter** playable manually or resolved automatically by AI controllers **using the exact same rules engine, RNG and resources**. First vertical slice must prove one limited combat case without requiring the full ability library.
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

## 2C. Tactical battles with shared manual / auto-resolve engine (chosen direction)

### Feasibility and principle

A classic **FF Tactics-like square grid**, initially drawn in Godot 2D (with future isometric visual projection if desired), is achievable in incremental slices. The expensive part is *not* drawing tiles: it is consistent rules, spell/ability interactions, performance, AI choices and the long-tail of class features. We should **never** maintain separate "manual damage" and opaque "auto combat odds" engines: that would systematically misrepresent specialised builds and make the extensive progression game meaningless.

Use the following architecture, implemented **outside the debug world fixture viewer**:

| Layer | Responsibility | Manual / automatic distinction |
| --- | --- | --- |
| **Rules/content data** | Abilities, skill/feat/class progression, save/DC/attack checks, resistances, statuses, resources, costs and legal actions | Identical for all controllers |
| **Combat state & simulator** | Immutable inputs + mutable battle state: participants, teams, initiative/order, position/facing, occupancy, terrain modifiers, turn/tick, conditions, active resources, RNG state and action/event history | **One authoritative deterministic simulator** |
| **Command validator** | Legal movement, range, LOS, adjacency/AOE, prerequisites, action economy, resource costs and targeting; rejects invalid AI or user commands the same way | Shared |
| **Manual controller** | Converts clicked grid choices and character actions into validated commands; UI is a projection of state | Human decisions |
| **Automatic tactical policy** | Reads identical public battle state and *per-character tactics*: goals, positioning, targets, danger, heals, retreat, spell/resources, teamwork; chooses commands | AI decisions |
| **Battle presentation** | Highlights, movement/sprites/effects/animations, event log, previews, fast-forward / instant end, results | Manual displays actions; auto can replay or calculate rapidly headlessly |

Both routes run **exactly the same transition** for a command, damage roll and condition trigger. Fixed initial seed + state + policy version + ordered commands reproduces results; user manual decisions may legitimately lead to different outcomes from AI decisions. Save battle result and durable campaign consequences once; reloading should not reroll resolved encounters. Auto must **not** silently use extra resources, ignore prerequisites or make hidden information available to AI.

### Auto-resolve must be a real feature, not a placeholder formula

- **Initial policy:** predictable utility/tactical heuristics for attack target, safe movement, heal/defend, debuff/control, retreat, AoE avoidance, protecting vulnerable party members and conserving limited daily powers.
- **Player control:** per-adventurer configurable stance/tactics such as aggressive, conservative, support, ranged, protect ally, use consumables only if emergency, hold an expensive spell, retreat below health threshold. Later guild contracts can run autonomous squads with instructions and the same battle engine.
- **Trust:** preview qualitative tactical risk and likely resource costs where evidence supports it, but don't claim numerical odds without calibrated simulation. Show battle log, roll highlights, injuries, spell use, XP/rewards, casualties and a replay/debug seed so a bad auto result is understandable.
- **Quality:** replay the same seeded encounter with saved policy settings and compare headless/visible results; verify win/loss invariants, legal action count and resources. Benchmark many seeds and AI policies and examine tactical *regrets*, illegal actions, retreats, healing priorities and specialist class skill usage. More AI strength comes later; simulation quality is an iterative subsystem.
- **Simulation speed:** fast-forward by skipping animation and rendering only on changes; no per-frame Godot nodes for each simulated turn. Thousands of test battles should run headlessly and produce aggregate *test data*, not become player-facing probabilities by default.

### First combat vertical slice (scope lock proposal)

**Three player units vs two or three enemies**, a small **square-grid 2D** field, obstacles and terrain cover, turn-based initiative/order, movement, melee/ranged attack, one class ability, one condition, one healing or defensive power, limited resources, victory/defeat/retreat, battle summary and **manual/auto switch**. Move to isometric presentation or fancy animations only after validation. This first test is a proof of the simulation and controllers, **not** a complete Pathfinder implementation.

Start with enough class/ability **diversity** to challenge the model (e.g. martial, stealth/mobile and spell/control roles), plus a test feature with an unusual trigger. Test that an AI party's resources, status effects and positioning are never bypassed by automatic results.

### D&D 3.5 / Pathfinder 1e systems and long-term class depth

**Confirmed baseline (3 October 2026):** a **somewhat simplified Pathfinder 1e-derived d20 foundation**, keeping PF1e-style consolidated skills, combat manoeuvres, regular feats, customisable class archetypes and multiclassing, and deliberately **adapting** D&D 3.5's large supplement-rich prestige-class catalogue into those consistent mechanics. This is **not** a verbatim dual-rules implementation: convert class entry prerequisites, skill ranks, feats, progression and exceptional actions into explicit PF-derived equivalents, recording the conversion and content version. Pathfinder archetypes and prestige classes must both remain available. The original base books remain references for mechanical intent/flavour, not a second simultaneously active ruleset. Simplifications must be centrally specified and deterministic, not silent changes to individual classes.

**Character identity and progression** should preserve:
- Race/heritage, chosen background, ability scores/modifiers, alignment or ethos as a system if selected, saving throws, BAB/attack progressions, AC/defences, initiative, hit dice, movement, resistances.
- **Full multiclass level history**, base/prestige class entry prerequisites, class features by level, spellcasting progression, caster level, spell slots/preparation/spontaneous casting, domains/schools, familiar/companion, resources per rest/turn and equipment feats where applicable.
- Skills/ranks, cross-class or class skills *according to the chosen version*, feats/bonus feats/feat chains, proficiencies, class-specific feats and exceptional feature interactions.
- Class identity beyond bonuses: distinct ability triggers, optional choices, conditional conversions, auras, reactions, tactical roles, situational drawbacks and narrative/guild/quest hooks that make prestige paths worth pursuing.
- Stable data IDs/content versions; a saved class progression cannot change just because an icon, name, text or mod pack was edited. Requirements are evaluated by rules, not GUI strings.

**Content-first system architecture (the long-term extensibility hinge):**
- Class, prestige class, race, feature, feat, spell, item and condition definitions live in **versioned data packs** (JSON/Godot Resources) with stable IDs, tags and shared effect primitives.
- A **declarative requirement/effect model** describes common mechanics (ability/skill/BAB prerequisites, caster spell level, trained skills, faction memberships, on-hit effect, conditional bonuses, resources, status application, triggers and target selection). Standard stacking policies are explicit.
- **Event/trigger hooks** (on turn start/end, on attack roll, on hit/critical, on spell cast, movement/enter tile, reaction/interrupt, damage taken, death, rest) and scoped scripts/components implement *genuinely* novel prestige mechanics. Exceptional features must be deterministic, testable, sandboxed and not magical ad-hoc branches in a single combat class.
- A class can grant abilities of already-defined kinds, yet still use unique combinations; share implementation where mechanics overlap without losing flavour. Later data packs can introduce new mechanics through a vetted API rather than schema rewrites.
- Validation tool imports and checks content IDs, circular prerequisites, spell references, invalid advancement tables, bonus stacking, missing text/art, tier-level availability and regression examples **before** classes become selectable/recruitable.
- NPC/world/guild candidate generation chooses *valid* multiclass/prestige paths deterministically with coherent equipment/roles; it cannot simply sample an advanced prestige class without satisfying entry prerequisites.
- UI requires build planner/level-up, prerequisite explanation (including why locked), class discovery, skills/feats/spells management, equipment and a combat build summary. Keep the playable v1 thin; don't ship hundreds of options in an unusable interface.

**Content scope:** do not promise verbatim imports of every 3.5 supplement early. Build 2–3 representative classes and at least one prestige-like progression example with a truly distinct triggered mechanic, then expand into dozens/hundreds through independently versioned content packs after the core rules engine is reliable. The architecture should support arbitrary packs without forcing rewrites, but **each rule needs validation**; a very broad but shallow catalogue is not equivalent to the deep 3.5 fantasy Mark wants.

**Copyright / provenance boundary:** underlying generic game mechanics and our own implementation can be modelled without reproducing protected setting text or artwork. Many 3.5 supplements contain material **outside** open SRD/licensed content. A personal-use goal does not establish rights to commit wholesale book text, art or source PDFs into a potentially shared GitHub repository. Track source/edition/licence per content pack; begin from authorised SRD/open material or original paraphrase mechanics. Build internal migration/name aliasing so future original terminology and art can be substituted without breaking saves.

### Perception, illusionists and non-damage tactical specialists (required architectural proof)

The design MUST support **characters who are effective without inflicting direct damage**, especially illusionists and unusual 3.5-derived prestige classes. Equal damage per turn is not the balance objective: effectiveness includes completing a mission with fewer losses, preventing damage, dividing enemy forces, controlling paths, conserving supplies, enabling escape or diplomacy, and reducing time/casualties.

**Essential state split** — the simulator knows objective physical world truth, but **each team or actor has an incomplete perceived battle state** and a saved belief/history of observations:

| Simulation layer | Example: illusory wall or phantom guard |
| --- | --- |
| Objective world | The wall has no physical collision. The conjured guard is not an actual armed unit. Real units/doors/terrain exist independently of appearances. |
| Visual/sensory observation | Enemy observer perceives an obstacle/person/cover, subject to line of sight, illumination, vision modalities, prior observations, magic senses and illusion properties. |
| Belief and reasoning | Undisbelieving enemies may route around the wall, target phantom guards or avoid a believed threat. Some may investigate or physically interact; others may ignore effects they are immune to or unable to sense. |
| Resolution and revealed information | Actions, contact, attacks, saving throws or magic sensing can change belief for particular actors; shared observations may influence comrades where communications justify it. Disbelief is neither universal knowledge nor automatically triggered without an appropriate event. |
| Player/AI controller | Both choose moves, targets, spells and tactics from the **same permitted observations**. No AI access to the simulator's omniscient ground-truth location/illusion flags or concealed enemies when selecting commands. |

**Mechanic distinctions (data-driven, per spell/feature):**
- **Figments and glamers:** apparently change objects, creatures, visual/aural/sensory conditions; can alter observed routes, perceived presence/cover or targeting without changing physical collision rules unless separately defined.
- **Patterns and phantasms:** may impose mind-affecting or sensory effects, saves/resistance and fear/confusion according to defined tags and specific target capabilities; immunity depends on tags and senses, not a blanket "mindless ignores all illusion" shortcut.
- **Shadow/partly-real effects:** later, support declared partial-real damage, interaction and disbelief rules; these must not be treated as ordinary completely nonphysical figments.
- **Direct defensive illusion effects:** duplicates, invisibility, concealment, false targets, blurred images and misdirection can reduce successful attacks or reposition allies without pretending to cause offensive damage.
- **Environmental context:** an illusory wall can convince a sight-reliant opponent to go around; it cannot genuinely block a mindless charging creature physically, stop a real projectile or force all creatures to fail disbelief. Different observers can hold different beliefs about the same tile.

**Rules and AI obligations:**
- Validator/action resolution must distinguish **apparent target availability** from **actual physical/effect resolution**. AI receives a filtered observed state rather than \`BattleState\` truth; spells and revealed clues mutate belief deterministically and generate replayable events.
- Saves and disbelief/interaction triggers follow the chosen PF-derived mechanic with explicit simplified exceptions. Spell tags specify school/subschool, senses affected, components, range, duration, DC/type, concentration, saving throw, immunity, disbelief trigger, and action/resource cost.
- Auto-resolve may choose "create false reinforcements", "conceal ally", "distract patrol", "make phantom barrier" or "retreat under cover" because those change positioning, enemy action allocation or victory objectives. Tactical evaluation should measure **avoided enemy actions, safe access, ally preservation, resource cost and objective completion**, not only expected damage.
- Expensive illusion spells must still spend spell slots/components/duration; observed reality and AI knowledge must carry through manual/auto switch and turn boundaries. Do not grant free auto-disbelief or auto-success to either team.
- Noncombat actions outside the grid (stealth, misdirection, infiltration, impersonation, escape, scouting, negotiation assistance, protecting a settlement, avoiding unnecessary fights) should be valid world/quest interactions with skill checks, factions, consequences and relevant senses. Contextual uncertainty and occasional resistant opponents are important for balance.

**First proof acceptance (before expanding hundreds of prestige classes):**

A seeded **three adventurers versus 2–3 enemies** combat where an illusionist has two concrete options (e.g., **decoy guard** and **illusory wall or mirror-image-like defence**):
1. At least one fooled enemy changes position, attack target or route. An enemy that investigates/disbelieves reacts differently. Actual physical collision remains correct.
2. Run the same encounter manually and via AI policy with controlled commands/RNG; identical commands yield identical state/events. Under auto AI, the illusionist chooses the deceptive feature for rational tactical reasons in relevant conditions instead of being scored as useless.
3. Demonstrate a resistant or inappropriate target, failure/success of saving/disbelief checks, spell usage tracking and persistent battle logs. AI must not see hidden illusion truth.
4. Show an early noncombat benefit (avoid patrol, stage distraction or gain safe passage) with a meaningful tradeoff and no universal guaranteed success.

This is an intentionally narrow illusion **slice**, not an automatic promise that all D&D/PF spells and sensory rules already work. A high-fidelity perception-and-belief system is one of the hardest elements of genuinely strong tactical auto-resolve: implement/test it incrementally, avoid per-class exceptions that rewrite the core battle state.

### Dependencies and deliverables

Design GAME-17 sets the **policy and data contracts**, not a multi-year exhaustive class feature list. After the world adapter (GAME-7), independently deliver: (1) rules/character engine and advancement, (2) pure deterministic combat core + replay/tests, (3) tactical grid and player controller, (4) auto-controller and headless evaluation, (5) content-pack import/validation and sustained class expansion. Each of those should be a scoped ticket, with the first shared-engine battle blocking a claim of a playable combat vertical slice. Persist world entities separately from rules pack mechanics.

## 3. Interaction / user-facing screens

The current `world_fixture_viewer.tscn` is **developer-only QA**, and must not be repurposed as the shipped New Game/map UI. Build distinct game presentation from reused renderer/data components.

| Screen | Minimum v1 | Deferred |
| --- | --- | --- |
| New Game | random seed and reroll, explicit seed, existing-world browser; state/province/region preview and eligible vulnerable hometown; three-character setup | full origin events, world-library sharing, advanced faction relationships, rich full classes/races/portraits |
| Strategic world | discovered geography, known towns/roads/major sites, select destination | omniscient political/marker display, dense debug panels |
| Settlement | name, defences/road context, job offer, rest, supplies | Settlemaker interiors, full commerce, complete NPC roster |
| Travel | route choice, ETA, risk, time progress and combat/event transition | travelling unit animation, fully animated world traversal |
| Combat | basic deterministic square-grid battle, manual orders or auto-resolve from the same simulation; readable outcomes and costs | advanced 3D elevation, all special action types, full spell catalogue, sophisticated enemy squads |
| Character | initial three recruits with attributes, class progression and one working cross-class ability/prerequisite example | hundreds of prestige classes, complete spell lists, comprehensive feat/item/class content catalogue |
| Site / journal | investigate or interact, discoveries and persistent status | full DungeonGen interiors, quests for all 36 marker types |
| Save/load | party+knowledge+visited/outcomes preserved | dynamic simulated world economy |

UI must focus on **the current choice and its consequences**, with the map artwork already accepted as the visual foundation.

## 4. GameWorld contracts needed next (GAME-7, not implemented here)

- `world_ref`: immutable world seed, generation version/recipe, world template identity/fingerprint, and stable source IDs for cell, state, province, burg, macro POI; no world identity derived only from editable names. Several independent game saves may reference the same generated world template, each with its own mutable changes. A new random-preview seed must not overwrite either saved world templates or game saves.
- `origin`: chosen state/province or future political faction affiliation, starting burg ID and optional home relationships. State/culture/province is what Azgaar currently provides; **do not equate those automatically with future guild factions** until GAME-10. A random start still resolves to stable IDs and stores the exact committed choice.
- `roster`: all persistently recruited adventurers with unique character IDs, race/background, ability scores, skill ranks, class-level history, feat selections, equipment, class resources, spellbook/preparation (where applicable), health/conditions, availability, guild membership and assignment. Prestige levels and exceptional abilities do not replace earlier classes; **multiclass progressions are first-class save data** and must reconstruct deterministically from pinned rules/content versions. Recruiting a member must not force them into every expedition.
- `party` / `expedition`: selected **subset** of the roster, distinct from the full roster and later guild membership. Participant count must obey `minimum_slots <= selected_count <= maximum_slots` for a job/POI-specific activity, with independently validated role requirements and situational constraints. No single cap should hard-code roster/guild capacity.
- `game_clock`: deterministic world time and events processed once, not reset on opening UI; carefully defined travel units.
- `knowledge`: separate **objective** world POIs from rumoured/discovered/visited/cleared player knowledge. No renderer access that directly reveals un-discovered sites.
- `journey`: selected start/destination via cell/road graph, path or segment IDs, risk estimate, start/end ticks, resolved encounter outcomes. Route safety refers to road and protection context, not an untested universal constant.
- `site_state`: keyed by stable macro POI identity, initial deterministic baseline plus mutable history (visited, investigated, rewards exhausted, consequences).
- `settlement_state`: stable burg reference and limited job/stock/defence state; later GAME-19 Settlemaker and GAME-29 guild rosters attach lazily via stable IDs. Re-entering a town does not reroll its characters.
- `save_version`: versioned per-save mutable deltas, atomic writes and migrations when schema evolves; encryption optional and **not required** for persistence.

**Crucial:** keep immutable Azgaar geography and procedural starting values separate from player-affected changes. New local sites can later hang off stable world and region IDs from GAME-21; DungeonGen/Settlemaker should never regenerate all interiors on world creation.

## 5. Risks and guardrails

- **Scope inflation:** the eventual rule/content library may be extremely extensive, but a first playable loop only needs a narrow tactical proof with manual + auto. Do not block first gameplay on hundreds of classes/spells, a complete guild economy, local-region generator or final character-creator UI. Design the contracts extensibly now and populate catalogue in independently tested batches.
- **Travel authority:** don't equate visual SVG road/rivers with canonical route traversability; use known Azgaar graph/metadata only when verified. Avoid invented exact geographical distances in the MVP.
- **Reveal control:** GAME-22 debug click inspection is a test facility, **not** permission for the player to click any unknown site.
- **Determinism:** encounter outcomes must depend on world seed + stable encounter ID + time/visit sequence, then be committed to save state. Reload must not permit rerolling a resolved event by accident.
- **Settlements:** no global spawning of NPCs, guild rosters, town layouts or dungeons; instantiate lazily when approached, keep persistent IDs and deltas. Small hometowns should use real burg size and verifiable access to roads/fortified protectors. Militia, protection pledges or guild patrols must be generated in the later protection system rather than fabricated from map appearance. If a selected region lacks eligible frontier homes, offer a clear fallback to the nearest eligible region, let the user change region, or flag the constraint—do not invent a settlement.
- **Assignment capacity:** validate both entry/route constraints and the contract's party-size limits before travel/participation. A large guild roster must not be confused with one expedition. Do not make lower difficulty automatically equal a smaller cap or make larger parties trivialise stealth, supplies or encounters.
- **Readability:** at normal/dense world zoom, keep map-key/glossary and visual decluttering rules, but design game-specific controls instead of shipping DEV LAYERS.
- **Narrative tone:** protect the black-magic road-and-fortress premise. A generated map isn't a quest in itself.

## 6. Implementation priority: a small playable spine plus one visual content track

**Next real implementation is GAME-7, not a full town/dungeon generator or an entire character creation screen.** Before starting, accept the scoped action economy/first vertical-slice details in this design PR. Then build these as **separately reviewable, small PRs**:

### Track A — playable game and combat foundations (primary)

1. **GAME-7 — small permanent GameWorld/save foundation**: load a pinned Azgaar world, preserve version and stable IDs, choose an actual source-backed state/province/small home burg, initialise a **skeletal party of three**, create **independent saves sharing the same world** and prove reload of player-known sites/other per-save deltas. No massive all-fields schema, finished creator, fake town guilds or combat. First visible result can be a plain functional New Game test screen showing chosen home and party/save state.
2. **GAME-32 — character rules core**, not finished creation UX: begin with 2–3 representative base classes (martial, scout and illusion/control) plus a class/prestige progression test; feats/skills/unique ability definitions and legal level-up checks in a versioned PF1e-derived rules pack with adapted 3.5 prestige requirements.
3. **GAME-33 — shared deterministic combat engine**: three starting characters versus 2–3 enemies, a bounded grid, movement, attack, defensive/illusionary control and headless repeatable results. **GAME-34** manual grid controller and **GAME-35** tactical AI/auto-resolve subsequently drive this **same simulation**.
4. **GAME-8/GAME-9** real player-facing world map and rerollable/new-or-existing world → region → vulnerable small hometown selection. **GAME-10** enriches real factions and player discovery. Connect the one job/travel encounter/return/reload loop and keep it small.
5. **GAME-36** deeper prestige content grows over time and is validated against the rules/combat system; do not require hundreds of classes before playable tests.

### Track B — visually rewarding generators (parallel only when foundations permit)

1. **GAME-21** one **local-region generation spike** soon **after GAME-7's world/location identity test**. Anchor to existing source world seed and cell/burg ID; open one deterministic region with routes/POI hooks in a small Godot test scene. It can progress while GAME-32 rules work is underway without redefining shared IDs, save format or world physics.
2. **GAME-19 Settlemaker** on-demand geometry for one source-backed small hometown, persisting local changes separately. Avoid generating or hardcoding guild NPC roster inside vendor code.
3. **GAME-20 DungeonGen** on-demand one dungeon tied to a stable discovered site ID, with identical revisits and saved outcomes.
4. Only connect larger town/dungeon catalogues after a single generated local region/town/dungeon can participate in an actual expedition and reload correctly.

**Why this order:** our main engineering risk is interactions between elaborate character abilities, deterministic combat, strong AI and persistent outcomes. More procedural geometry is visually satisfying but easier to add **once the owning world/game/save identities are stable**; doing all the generators first risks another impressive static world with no playable loop. Track B still gives frequent new sights/screenshots while rules-engine work develops.

## 7. Decisions for Mark before this design can be accepted

**A. Primary role — CONFIRMED**  
Directly command and customise an adventuring party; begin with three members (provisional count), expand the roster through recruitment, and potentially lead multiple teams as a guild grows. The player can join an established guild, or attempt the harder, slower route of founding one independently.

**B. Opening — DIRECTION CONFIRMED**  
Choose (i) a random rerollable seed, manual seed, or existing generated world; (ii) a preferred region/state/province/political affiliation where supported; and (iii) a **small vulnerable home village/hamlet** in that region, preferably near stronger protection. The **region** is the main geographic choice, not exact town optimisation. Hometown loyalty is emergent, never mandatory. Inciting incidents may vary by local conditions; no universal forced catastrophe. Remaining details—exact protection-distance rules, number of candidates, and how existing-world browsing works—are design parameters, not final thresholds.

**C. Combat direction — CONFIRMED**  
Mark wants **grid-based Final Fantasy Tactics-style battles** with **manual control or powerful auto-resolve**, not narrative-only conflict. Use a single deterministic battle simulation, with manual commands and AI policy as interchangeable controllers; do not create a fake auto-win-probability shortcut. Build a small, real battle first, then scale ability and class breadth. The **streamlined PF1e-derived baseline and adapted 3.5 prestige content** are selected; detailed simplifications, action/initiative/grid conventions and initial feature interactions remain to be specified.

**D. Party and contract capacity — AGREED IN PRINCIPLE**  
Initial travelling party of **three**, individually customisable; later recruit a larger roster. **Per-job and per-POI hard participation limits**, independent of roster size, rather than sending everyone to every activity. Exact limits are balancing parameters, not final gameplay rules. A normal travelling formation of up to ~six adventurers is a **working proposal**, not an approved universal limit; exceptional defences/multisquad operations may be larger. Small-team restrictions may reflect space, concealment, escort capacity or logistics. See the assignment-capacity table below.

**Acceptance for GAME-17 design:** A (party perspective), B (frontier-home world selection), C (manual grid tactical + shared-engine auto), initial three characters and **the streamlined PF1e-derived baseline with converted 3.5 prestige content** are chosen. Before marking design Done, settle detailed core action economy and a representative illusion/control encounter as part of the minimal battle and travel sequence. Then GAME-7 GameWorld contracts and the new scoped combat/character engine issues can proceed.
