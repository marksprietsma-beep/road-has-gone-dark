# Cross-system design checkpoint — 16 October 2026

**Status:** Design round complete through Question 22. Accepted decisions are documented; features are **not implied to be implemented**. Subsequent clarifications should be asked **only when an actual delivery dependency requires them**, not as a continuing general questionnaire.

**Authoritative references:** [canonical glossary](../../CONTEXT.md), [ADR 0001 — immutable World Template and Playthrough separation](../adr/0001-world-template-playthrough-boundary.md), [ADR 0002 — bounded world/NPC/character life](../adr/0002-bounded-offscreen-world-simulation.md), [ADR 0003 — settlement/stronghold development](../adr/0003-player-holdings-strongholds-and-settlement-management.md). This checkpoint is a navigation and handover summary; where detail differs, those definitions and ADRs govern.

## Accepted decision register

| Question | Recorded decision | Canonical home |
| --- | --- | --- |
| Existing baseline | Generated World Template is immutable; each Playthrough owns evolving state and Player Knowledge | ADR 0001 |
| Q1 | World advances through bounded, consequential situations; no continuously simulated universal world | ADR 0002 |
| Q2 | Track situations by personal/regional significance plus selected major distant developments, not merely visibility/proximity | ADR 0002 |
| Q3 | Meaningful warnings and response opportunities for consequential personal threats, with credible irreversibility | ADR 0002 |
| Q4 | News arrives through plausible and imperfect in-world information channels, not omniscient instant notices | ADR 0002 |
| Q5 | Distant intervention is earned through contacts/delegates and constrained by capabilities and communication | ADR 0002 |
| Q6 | Delegates exercise bounded independent judgement within agreed mandates | ADR 0002 |
| Q7 | Significant NPCs pursue their own ambitions and relationships through bounded personal events | ADR 0002 |
| Q8 | NPC significance can emerge or recede; existing identity, relationships and consequences are not erased | ADR 0002 |
| Q9 | Significant NPCs form sparse, consequential NPC-to-NPC relationships | ADR 0002 |
| Q10 | NPC beliefs depend on plausible evidence, rumours, reports and observation; world truth, NPC belief and player knowledge differ | ADR 0002 |
| Q11 | Contextual motivation conflicts may involve a bounded, persistently committed, stat-aware roll when the choice is genuinely uncertain | ADR 0002 |
| Q12 | Use compact enduring personality priorities in addition to D&D abilities/skills, not a giant numerical personality simulator | ADR 0002 |
| Q13 | NPCs and player adventurers share personality concepts; player decisions remain authoritative for their adventurers | ADR 0002 |
| Q14 | Personality changes at meaningful milestones; player confirmation for adventurers, grounded event-driven NPC changes | ADR 0002 |
| Q15 | Extensive player-owned strongholds and settlements are a committed long-term pillar, beyond cosmetic housing | ADR 0003 |
| Q16 | Appointed NPC administrators run settlements during expeditions with meaningful autonomy and delayed oversight | ADR 0003 |
| Q17 | Acquire existing holdings **and** found new settlements in geographically/resource/politically plausible locations | ADR 0003 |
| Q18 | Plan functional districts and individually place important buildings, roads and walls; ordinary infill is procedural | ADR 0003 |
| Q19 | Regional, interdependent production chains and meaningful transport/access constraints; routine flows delegated | ADR 0003 |
| Q20 | Population, workforce and needs use aggregate cohorts; consequential specialists/leaders have persistent individual NPC identities | ADR 0003 |
| Q21 | Contextual community needs and social pressures affect settlements, without continuous happiness-meter upkeep | ADR 0003 |
| Q22 | **Property ownership, physical control and governing legitimacy are distinct**; authority can be earned, negotiated, inherited, appointed or contested | ADR 0003 |

## Architectural coherence and boundaries

1. **One world, separate truth and perspectives.** The World Template's geography and starting settlements do not mutate. Playthrough-owned changes (including founded settlements) and NPC/Party knowledge have their own persistence and information boundaries. Physical ownership, practical force and recognised governing powers cannot be collapsed into one ownership flag.
2. **Consequences without universal continuous simulation.** The destination has depth, but advancement should remain bounded, relevant and reproducible. Aggregate workers and economic flows are consistent with deep strategic decisions. Named key people, situations, shipments and political disputes can receive individual treatment when consequential.
3. **Character decisions are mechanically grounded without losing agency.** Existing D&D abilities/skills inform competence and contextual rolls; personality priorities and relationships inform motives. NPCs act within known information and obligations. A player-created adventurer's personality cannot forbid an otherwise legal player choice.
4. **Settlement and adventure loops must exchange real causes.** Exploration can yield resources, contacts, information, claims and threats; settlements can create equipment, allies, disputes, regional politics, logistical vulnerability and new reasons to adventure.
5. **Visual and gameplay state must agree.** Districts, placed landmarks, founded settlements and persistent development must be reflected in actual local/town visualisation when implemented, preserving anchored terrain and existing important buildings. Legacy settlement research is evidence, not automatically merge-approved gameplay.
6. **Do not mistake this design record for finished production.** No new settlement simulation, administrative AI, politics engine, economy, construction editor or character-personality implementation was delivered by the Q1–Q22 documents. Do not introduce Linux CI; follow the project’s native Windows verification practices when an implementation is later authorised.

## Delivery order and ownership

**Current priority: [GAME-123](https://linear.app/marksprietsma/issue/GAME-123)**, the rich, game-ready character milestone. Continue to prove meaningful ancestry/build diversity and actual abilities in native combat and noncombat opportunities, with persistence and playable Windows evidence. It should not be displaced by the newly enlarged settlement ambitions.

**Future programme: [GAME-125](https://linear.app/marksprietsma/issue/GAME-125)**, extensive holdings, settlements and governance. Once the character/adventure proof is sufficiently credible and a narrow development slice is specifically approved, define an **incremental vertical slice**, not a full economy at once. One candidate proof—**not yet authorised**—could connect a single geographically anchored holding, one administrator, a planned district/placed landmark, one meaningful supply dependency, a cohort and significant resident, and a small legitimacy/community dispute. The value is to validate cross-system persistence and gameplay, not to lock in those counts or recipes.

**GAME-124 design round:** close after this checkpoint and Q22 are merged. Do not automatically open Q23. Record any new blocking implementation-specific design question in the owning delivery issue when it genuinely arises.

## Still open; do not silently decide

- Setting-specific land title, authority powers, legal institutions, tax privileges, disputes and claim transfer procedures.
- Administrator mandate limits, appointment/replacement, policy interfaces, response windows and message delays.
- Construction map/placement geometry, procedural infill constraints and town-renderer integration.
- Production recipes, resource balances, supply capacity, markets, depletion, upkeep and exact transport resolution.
- Population cohort categories, labour productivity, migration and community-needs formulas.
- Exact personality vocabulary, weighting and milestone criteria; evidence credibility and social outcomes.
- Scope/validation/Windows test budget for the first approved implementation slices, balanced against existing GAME-123 work.

These unresolved items **do not reopen the general design questionnaire**. Decide them just in time with implementation plans, acceptance criteria and evidence.
