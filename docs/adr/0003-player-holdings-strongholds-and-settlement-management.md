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

## Open design dependencies — not yet answered

1. **Delegation is settled:** administrators operate during Party absence with strategic oversight and delayed communications. Still decide their mandate limits, player policy controls, emergency decisions and reporting detail.
2. Which kinds of Holdings can be acquired, founded, leased, conquered or governed; whether players may develop entirely new settlements versus existing locations.
3. Depth of physical placement/customisation, production/logistics, residents, taxation, factions, territorial control and conflict.
4. Management pacing, travel-time and information delays, simulation boundaries, balance, failure/recovery and how political legitimacy is earned.
5. If and how personally owned properties differ from guild holdings, settlement governments, companions' property and collective faction assets.
6. Vertical slice, performance/QA budgets and realistic sequencing relative to the existing character-first programme (GAME-123), game-world integration and basic adventure loop.

**Do not begin gameplay implementation, introduce Linux CI, or claim any of these unresolved mechanics have been designed.** This ADR establishes the strategic destination and the interface obligations for later design work.
