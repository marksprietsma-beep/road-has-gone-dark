# Develop player holdings into strategic settlements and strongholds

**Status:** Accepted — 16 October 2026 (Q15; long-term product ambition only, not implementation authorisation).

## Decision

**The Road Has Gone Dark must support extensive player-owned property, stronghold and settlement management** as a meaningful strategic RPG pillar. Ownership may grow beyond a cosmetic house or a small list of crafting facilities into developed holdings with production, workforce and population considerations, construction and infrastructure, trade and resources, military protection, governance and political relationships. Such management has material, persistent consequences in the world.

This accepts the user's **Option C**, rather than the previously recommended lighter Option B. Do not quietly downgrade the destination into cosmetic housing or a handful of passive buff buildings. Conversely, the acceptance does not specify that settlements must be the first implementation milestone, that every worker requires a personal simulation, or that the party must constantly micromanage.

## Why this belongs in the same game

The adventuring and settlement layers should influence one another:
- Expeditions may discover resources, obtain building materials, win contracts, gain allies, resolve threats, recruit specialists or shape claims to land.
- Holdings can provide work, housing and opportunities for known characters; workshops, production and infrastructure can affect items, services, travel and party preparation.
- Local prosperity, shortages, taxation, legal authority and disputed territory may alter relationships, faction influence and political choices.
- Fortifications, garrisons, hired groups and alliances can alter the outcome of consequential threats; settlements remain vulnerable under the fair-warning and credible-communication boundaries.
- Results must be coherent with established settlements, geography, Site identities, NPCs, regional developments and the party's evolving history.

These are **types of strategic decisions and interactions**, not an approved catalogue of buildings, economic formulas, construction UI or production chains.

## Authority and simulation boundaries

A **World Template** defines original geography, settlement locations and immutable generated facts. A **Playthrough** owns its Holdings, construction and development decisions, control/claim state, inhabitants and economic/political consequences. New or developed locations must not rewrite the template; use stable world anchors and recorded playthrough-specific changes or entities, subject to future creation/location rules.

The existing accepted **bounded consequential world simulation** (ADR 0002) still applies. Deep management need not require continuously simulating each household, factory, worker, caravan and official. Plausible aggregate or event-based advancement remains a candidate **implementation technique, not a settled economic design**. Significant events and off-screen changes require reproducible persistent outcomes. NPC agency, delegation, beliefs and information channels remain relevant where governance and orders depend on people.

Reject **cosmetic housing only** and **limited functional home only** as the *final intended scope*. Neither is sufficient for this long-term destination. A small incremental vertical slice may still be useful later, but that must not redefine the committed product direction. Avoid a disconnected city-builder whose resource system ignores the adventuring world.

## Delegated administration with strategic player oversight — accepted 16 October 2026 (Q16)

**A player-controlled settlement continues functioning while the Party travels**, under appointed NPC **Settlement Administrators**. The player establishes strategic priorities and suitable instructions, appoints or replaces people in authority, and provides resources and oversight. Administrators manage ordinary operations and can take consequential local action within their agreed **Mandates**, rather than freezing settlement progress until the player visits.

Administrators are consequential characters, not perfectly obedient production optimisers. Their competencies, values, obligations, loyalties, relationships, understanding of the situation and available resources may affect responses. Circumstances can require adaptation or refusal under the already accepted bounded-NPC-judgement boundary (ADR 0002). Appointing capable people and establishing functioning institutions should matter; no universal manager AI or continuous worker-by-worker simulation follows from this decision.

**Information and orders are not instantaneous across distance.** Credible channels (messengers, travellers, trusted contacts and organisations) convey delayed and possibly incomplete reports or instructions. The player may intervene from afar through established influence where travel time, access and relationships allow, or return in person for more immediate control. A local emergency may need resolution before a message can arrive. Results, resource effects and important decisions persist in the Playthrough; they are not rolled back when the Party returns.

Reject both **presence-gated management**, which would make extended expeditions prohibitively disruptive to an extensive strategic settlement system, and **omniscient global remote control**, which would negate meaningful travel, communications and delegation. The principle of continuous consequential operation does not impose a calendar-tick economy, automatic daily notification system, prescribed policies or fixed administrative hierarchy.

**Still unresolved:** the exact scope of administrator mandates, ways to appoint/remove or replace them, what standing policies players may define, the separation of routine and exceptional decisions, the timing/accuracy of reports, multi-settlement coordination and the handling of governance disputes. This decision is design authority only, not approval to implement an administration engine.

## Acquire existing holdings or found new settlements — accepted 16 October 2026 (Q17)

Players may **acquire authority over existing holdings and settlements** and may also **found entirely new settlements** at plausible locations. A new camp or outpost can grow into a village, stronghold, town or more influential centre through subsequent development. The ability to found a new settlement is a committed product capability, not merely a cosmetic upgrade to pre-generated towns.

Founding must respect **world geography, usable local resources, access and surrounding territorial or political circumstances**. A fertile valley with water and routes could be a plausible candidate; inaccessible terrain, scarce resources or competing claims can introduce meaningful constraints and consequences. Being geographically suitable is not proof of lawful ownership, neutrality or universal permission. Acquisition and founding can involve social/political paths, but exact allowed transactions (purchase, inheritance, lease, negotiated charter, conflict, etc.) remain to be agreed individually; don't silently guarantee every acquisition mechanism or unconditional conquest.

Original **World Template** settlements and geography remain immutable source-world facts. **Founded Settlements** are Playthrough-specific entities anchored to legitimate world geography with stable identity, saved state and history; control changes to existing settlements and new construction are also Playthrough-specific. Development should not retcon existing Site positions, neighbours or strategic geography. Other Playthroughs sharing the World Template remain independent.

Reject **existing-settlement-only ownership**, which would deny the approved founding capability, and **unrestricted founding anywhere**, which would undermine geography, resources, routes and political context. This does not prescribe a grid-building system, building catalogue, founding cost, minimum map distance, placement resolution or ownership procedure.

**Still open:** land-rights recognition and disputes; how eligible sites are presented; founding sequence; whether new settlements can later gain full administrative/political autonomy; exact construction geometry and district constraints; relationships with existing kingdoms, guilds and neighbouring settlements; and how population, resource limits and political legitimacy affect later growth.

## District planning with selected individual placement — accepted 16 October 2026 (Q18)

Players **plan the functional districts of their settlements and individually place consequential buildings, roads and fortifications**. Residential, commercial, agricultural, industrial and other areas can be designated on a location-grounded town layout; their **ordinary structures develop procedurally**, subject to population, resources, access and relevant constraints. The player need not manually position every house or decoration, but should have meaningful influence over overall shape, strategic access and settlement identity.

Important facilities, strongholds/castles, workshops with distinctive roles, major civic buildings and defensive works may warrant individually controlled positions when placement has material gameplay or visual meaning. A settlement's actual appearance must reflect its committed district, building, road and wall changes rather than showing static art while only internal management menus advance. The same stable Playthrough settlement data should inform gameplay and visual representations, including future integration with generated town layouts and the broader world.

Procedural infill is **bounded by existing established geometry and structures**: new houses or facilities cannot silently move roads, important Sites, established buildings or original geography. New settlement entities and modifications are recorded as Playthrough-specific outcomes; the immutable World Template does not change. District access, resource availability and relationships with neighbours can constrain expansion, without requiring constant individual-house AI.

Reject **purely abstract upgrade menus**, which would not deliver the user's requested physical customisation, and **mandatory per-building placement of every ordinary home**, which would turn broad strategic governance into repetitive layout work. No decision has yet been made on precise map scale, build grid, road-network representation, fortification geometry, district editing costs, procedural infill algorithm or which buildings qualify for manual placement. The choice is an interaction and fidelity boundary, not authorisation to build a construction editor or new renderer.

## Regional production chains and meaningful logistics — accepted 16 October 2026 (Q19)

The settlement-management pillar will include **connected production chains between specialised settlements** and consequential logistics. Resources sourced from local geography and facilities (for example ore, timber or crops) can be processed, consumed or supplied to other settlements' workshops, construction, provisioning and economic activities. Meaningful material dependencies, available capacity, workforce and supplies determine what development and production are possible; buildings are not solely passive generators of generic currency.

Trade and supply must respect **real geographical access, routes, transport capacity, distance, security and credible delays**. A mine, foundry and agricultural settlement can complement one another, but goods are not instantly available across the world because the player owns all three. Threats, disruption, shortages, expensive journeys and new opportunities can change production and create actionable exploration, protection, diplomatic or infrastructure goals. Important changes and outcomes must be recorded in the owning Playthrough without rewriting World Template geography.

**Routine operations belong to appointed administrators** under accepted Q16 mandates and their access to information. The player determines high-level development, strategic priorities and responses to exceptional events, while ordinary supply planning and production work can proceed during expeditions. Use the existing bounded off-screen-event, NPC judgement, player-knowledge and reproducibility principles; this is not a requirement for continuously running individual wagon AI, tracking each employee or exposing all hidden economic truth.

Reject **merely abstract categories of passive income with negligible inter-settlement dependencies** as the final goal, and reject **mandatory item-by-item production batching, per-worker actions and physically simulated every-wagon transport** as the required level of detail. This does not forbid meaningful caravans, named trade deals or individual important transports when a particular event warrants one.

**Still unresolved:** resource catalogue and transformation recipes, quantity/quality granularity, storage, production and upkeep pacing, resource depletion/replenishment, precise labour/cohort accounting and specialist capacity, transport capacity and scheduling, market and contract details, administrator policies, route damage/security costs and exactly how players intervene. Do not prescribe numerical rates or a simulation implementation from this decision alone.

## Aggregate population with individually persistent significant residents — accepted 16 October 2026 (Q20)

Represent a settlement's ordinary **population and workforce as bounded aggregate Population Cohorts**. Groups can account for occupational capacity (miners, farmers, artisans, builders, guards, and other relevant workers), available labour, broadly relevant demographics and settlement needs without requiring separate character records, daily routines or relationships for every inhabitant. Coherent changes to size, availability or circumstances alter persistent Playthrough labour and production capacities and can drive consequential events under the accepted regional production model (Q19). This approves the **granularity distinction**, not specific demographic dimensions, arithmetic or welfare thresholds.

Track important specialists, administrators, influential leaders and other **Significant Residents as persistent individual NPCs**, reusing the significant-NPC life boundary from ADR 0002. Their existing skills, personality priorities, obligations, beliefs, relationships and recorded histories can materially affect settlement outcomes: losing twenty generic miners affects aggregate capacity, whereas losing the only capable master blacksmith might also affect specialist production, apprenticeships, relationships, promises and future opportunities. Do not treat a named specialist as a fungible workforce point or double-count their labour when they influence a cohort.

Significance is **dynamic**. An ordinary resident may become an individually represented NPC through a consequential action, an encounter with the Party, an influential role or important relationships, and later drop out of active personal development without their identity/history being erased. Promotion must preserve whatever already established, grounded circumstances are available; it must not invent a fully detailed personal biography or secretly retcon past world events when an aggregate citizen is first named.

This is compatible with the **bounded consequential world simulation** and NPC-specific knowledge rules; it does not require continuously running eight hundred lives for an eight-hundred-person town. Reject only total population counters, which erase important specialists and character-driven consequences, and universal individual simulation, which imposes costly routine household, schedule and relationship management. Exact cohort categories, occupational assignment, demographics, migration, labour productivity, specialist bonuses, unemployment, births/deaths and NPC-cohort reconciliation rules remain open for later design and validation. **No implementation is authorised by this record.**

## Contextual community needs and social pressures — accepted 16 October 2026 (Q21)

Settlement population prosperity and stability depend on **meaningful Community Needs and Social Pressures**, not solely aggregate wealth or production. Essential supplies, food, housing, safety, working conditions, perceived fairness and locally salient customs, expectations or governance can matter. These considerations may differ between settlements and Population Cohorts: a frontier mining town, a farming community and a large trading centre need not share one universal set of priorities or rank them identically.

Grounded shortages and grievances can affect **migration, participation in labour and production, trust in local administrators, cooperation, conflict, political loyalties and development opportunities**. Important developments should emerge through consequential Playthrough World Situations and the existing evidence-based NPC beliefs/relationships boundary. For example, hazardous mining conditions or unfair allocations might generate organised demands, negotiation, migration or unrest depending on the community, local leaders, history and the government's response. Prosperity does not automatically guarantee legitimacy, nor does modest wealth automatically imply unrest.

NPC **Settlement Administrators** may address ordinary supply and community issues under their Mandates while the Party is away, subject to credible information, resources and authority. Significant Residents can act through their own motivations and relationships; Population Cohorts express common practical conditions without requiring an individual satisfaction score for every person. Fair notice, plausible response opportunities and durable histories remain relevant when severe harm is foreseeable.

Reject **essentials-only population accounting** as too shallow for the accepted strategic settlement goal, and reject **continuous happiness-meter micromanagement** or dozens of continuously drifting needs as the required play loop. Routine absence must not automatically degrade settlement morale. Do not introduce rigid universal happiness cutoffs, arbitrary rebellion rolls or timed chores; model contextual, legible choices and their consequences.

**Still unresolved:** the needs categories used by particular cultures/cohorts, how priorities differ or change, representation and resolution of grievances, policy tools, welfare/production trade-offs, migration math, unrest thresholds (if any), what constitutes adequate warning and player response, and any numerical economic or population formulas. This acceptance is a design requirement, not authorisation for a social-simulation engine.

## Governing authority and political legitimacy are distinct from ownership — accepted 16 October 2026 (Q22)

**Owning a Holding, physically controlling territory and legitimately governing people are distinct states.** Buying a castle does not automatically grant jurisdiction over a neighbouring village, its mayor, council, taxes, defence obligations or existing allegiance. Equally, a ruler may exercise recognised authority without personally owning every building. A military occupation may confer practical leverage without recognised legal or social authority; opposition and consequences remain possible.

**Governing Authority can be earned, negotiated, inherited, appointed or contested** through credible local institutions and relationships. Relevant sources may include charters, customs, resident support, municipal councils, noble or faction agreements, inherited rights, recognised offices and political victories. The availability and credibility of each route depend on the world's existing institutions, claims, parties and events, rather than an unrestricted generic menu of titles. The player can challenge the existing order; doing so creates consequential risks and responses without automatically making a claim legitimate.

Authority is **scoped and contestable**. Different actors may recognise different rights; control of construction, local taxation, law, trade, militia or territory need not be bundled into one universal owner flag. Residents' trust, political alliances, obligations, evidence, grievances and competing Territorial Claims can affect which powers are accepted or opposed. Authority and legitimacy can change through justified World Events and persistent Playthrough history, respecting NPC Beliefs, limited information and fair response opportunities.

This accepts **contextual earned/contested legitimacy**, and rejects both property-as-automatic-sovereignty and power-alone-as-unconditional-recognition. Do not infer universal voting rules, a fixed feudal hierarchy, mandatory combat conquest, moral alignment effects or a single numerical legitimacy meter. A de facto ruler may remain powerful despite opposition, but those relationships and constraints cannot be silently erased.

**Unresolved implementation details:** the setting-specific kinds of institutions and charters, exact scope of governable powers, procedures for claims/transfers, challenges and appeals, enforcement, taxation, local representation, multiplayer/party ownership distinctions (if ever applicable), and how political disputes produce noncombat opportunities or armed conflict. No politics or law subsystem is authorised for immediate implementation.

## Open design dependencies — not yet answered

1. **Delegation is settled:** administrators operate during Party absence with strategic oversight and delayed communications. Still decide their mandate limits, player policy controls, emergency decisions and reporting detail.
2. **Acquisition, founding and the authority distinction are settled:** players can acquire existing holdings or found geographically plausible Playthrough settlements. Property title, physical control and governing legitimacy are separate and may be contested. Exact claim procedures, legal institutions, charters, authority scope and founding requirements remain unresolved.
3. **Construction, production, population and wellbeing direction are settled:** player-planned districts and placed key structures coexist with regional supply chains; residents' workforce and community needs use aggregate cohorts, while significant people persist individually. Supplies, housing, safety, working conditions, fairness and local priorities can cause consequential social pressures without a universal happiness meter. Exact editor geometry, recipes, quantities, transport, cohort/needs formulas, migration, taxation, factions, territorial control and conflict remain open.
4. Management pacing, travel-time and information delays, simulation boundaries, balance, failure/recovery, and the concrete procedures for acquiring, defending or changing politically legitimate authority.
5. If and how personally owned properties differ from guild holdings, settlement governments, companions' property and collective faction assets.
6. Vertical slice, performance/QA budgets and realistic sequencing relative to the existing character-first programme (GAME-123), game-world integration and basic adventure loop.

**Do not begin gameplay implementation, introduce Linux CI, or claim any of these unresolved mechanics have been designed.** This ADR establishes the strategic destination and the interface obligations for later design work.
