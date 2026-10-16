# Advance the world through bounded, consequential situations

**Status:** Accepted — 16 October 2026 (design decision; simulation implementation not yet authorised).

The Road Has Gone Dark will use **bounded, consequence-driven off-screen world simulation**. In-game time may advance persistent, meaningful **World Situations** affecting places, people or groups even when the player is elsewhere. We will not continuously model every NPC routine, settlement economy or world entity, and world changes need not all be directly player-triggered.

## Why this boundary

A static, player-only world would undermine the promised reactive fantasy setting: an unresolved bandit threat ought to be able to worsen, draw a response or otherwise change during a lengthy expedition. Conversely, a broad always-running simulation of hundreds of settlements and thousands of people would introduce high cost, hard-to-test cascading behaviour and unpredictable balance before the core adventure loop is proven. Bounded developments preserve agency and plausible off-screen consequences while keeping the simulation comprehensible, controllable and testable.

## Alternatives rejected

- **Continuous global autonomous simulation:** attractive emergence, but prohibitive design/QA burden and difficult causal coherence for the playable milestone.
- **Predominantly player-triggered changes:** simpler and easier to author, but would leave major threats and people unnaturally frozen when unobserved.

## Situation selection — accepted 16 October 2026

Use **significance-based simulation**, not a universal register of every generated circumstance. Keep a bounded set of tracked situations linked to the Party's activities, relationships, important people/places and relevant nearby threats, **plus a limited number of consequential regional or world developments** (for example, a distant war). Player ignorance does not by itself stop a genuinely major world development, but a remote minor bandit dispute need not advance just because it could exist in generated content. **Significance is not the same as proximity, and being tracked is not the same as being revealed to the player.**

Reject both purely local/personal advancement (which freezes consequential distant events) and advancement of every generated major threat (which recreates an unbounded simulation under another name). This refines the original bounded-world decision; it is not a new simulation architecture.

## Consequence fairness — accepted 16 October 2026

**Personally significant threats should normally provide fair warning and a meaningful opportunity for player response, but not guaranteed prevention.** Bounded off-screen development may produce irreversible outcomes, including loss of an important NPC, damage to player-owned property or the fall of a familiar settlement. Threats should have credible causes and intelligible progression; they should not randomly erase significant player investments without a realistic chance to affect the situation.

The player is free to ignore, defer or decline intervention. Protection of the hometown is not mandatory, and consequences are not suspended merely because the Party travels elsewhere. An intervention may change the severity or beneficiaries of an outcome without preventing the underlying event. Warnings should convey actionable stakes rather than perfect information about the hidden world; see accepted Information delivery boundary below. Serious unforeseen events elsewhere may still occur.

Reject automatic protection of all important possessions and relationships: it makes off-screen threats toothless. Reject unrestricted, unheralded destruction of personally meaningful things: it makes the simulation feel arbitrary and punishes exploratory freedom. No fixed grace period, notification system, minimum rescue chance or numeric escalation schedule is decided by this record.

## Information delivery — accepted 16 October 2026

Significant developments reach the Party through **credible in-world communication**, not an omniscient global notification system. Messengers, travellers, rumours, personal contacts, guilds and other organisations may convey reports about threats. Distinguish (1) what actually happened in the Playthrough, (2) what information exists or is travelling, and (3) what the Party has learned. A tracked off-screen situation can therefore advance without being exposed to the player immediately.

Communication can be delayed, incomplete or uncertain; knowing a warning does not imply knowing every detail or the guaranteed future outcome. Timing and reach should be plausible relative to geography, relationships and access to communications. **Do not require simulating every messenger's physical movements** to achieve this: the decision is about in-world causality and discoverable information, not a continuous courier engine.

The existing fair-warning commitment still applies to personally significant threats. Designers must support normally attainable, actionable advance warnings and meaningful responses consistent with travel and communication limitations, without forcing a particular intervention or promising rescue. How long warnings take, reliability/falsehood rules, the available forms and costs of remote response, and what happens when a channel fails remain undecided; do not invent fixed delivery times or notifications.

## Earned remote intervention — accepted 16 October 2026

The player may attempt to influence a distant tracked situation through **limited, earned remote influence**: established contacts, allies, guilds or hired agents acting within credible relationships and available authority. This provides a meaningful possible response when personal travel cannot beat an approaching deadline. A message, request, payment or commitment must be feasible in the world; time to communicate and mobilise, local resources, delegate capability, loyalty and circumstances can affect the result. Success is neither instantaneous nor guaranteed.

Reject **direct intervention only**, which would make some fairly communicated warnings practically unactionable, and reject **full remote management**, which would impose global command authority and a large management simulator inconsistent with a travelling-party RPG. Personal intervention should normally afford greater immediate control, not invalidate valuable relationships and delegation.

This is a **design boundary**, not implementation authorisation for a courier simulator, off-site combat engine, guild-management UI or universal NPC scheduler. Bounded independent judgement is accepted below; exact mandate boundaries, refusal procedures and reporting remain to be decided.

## Delegates' independent judgement — accepted 16 October 2026

An appointed **Delegate** acts within an agreed **Mandate**, with bounded independent judgement rather than either literal obedience or continuous self-directed simulation. They may adapt tactics to circumstances, honour established obligations, and decline unreasonable demands. Material decisions must be grounded in known competence, motivations, relationships, available information, resources and situational constraints, not unexplained betrayal or random loyalty rolls.

For example, an instructed militia captain facing an attack may divert defenders from a bridge to rescue trapped townsfolk when that is consistent with their documented obligations. This can change the defence outcome, costs or relationship with the player, and should be intelligible once an appropriate report reaches the Party. A Mandate does not guarantee success, perfect knowledge or unlimited authority.

Reject strict scripted obedience, which would make established identity and relationships mechanically hollow, and reject unrestricted autonomy, which would undermine predictable delegated objectives and demand expensive continuous NPC simulation. Routine absence alone should not create a punitive relationship-decay treadmill. Exact mandate constraints, refusal handling, outcome resolution, player-facing explanation and delegation scope remain to be worked out before implementation.

## Independent lives of significant NPCs — accepted 16 October 2026

**Significant NPCs may pursue their own established ambitions and relationships through bounded, persistent events**, including developments that occur while the Party is away and without a player-issued Mandate. An established blacksmith might relocate, pursue a workshop, change an allegiance or develop a rivalry through meaningful circumstances. Such choices belong to the Playthrough's history, preserve character identity and may create later player-facing opportunities or consequences.

This is distinct from the previously accepted **Delegate** behaviour: delegated judgement remains bounded by an agreed Mandate, while **NPC Initiative** serves that person's own motivation. An important NPC need not be recruited, personally known to the player, or geographically present for a relevant situation to develop. Equally, merely having a name does not require a schedule or evolving relationship graph.

Reject purely reactive NPCs whose ambitions freeze until a player clicks them, and reject continuous independent simulation of most named NPCs. Track relevant developments at significant decision points under the existing bounded-simulation and reproducibility constraints. Never substitute freeform generated prose for committed world and relationship facts; hidden off-screen developments must still respect the Player Knowledge boundary.

### Dynamic significance — accepted 16 October 2026

An NPC becomes significant through relationships, repeated player interactions, influential actions, positions of responsibility or major World Situations, rather than membership in a fixed initial cast. A player-connected merchant can become prominent through earned trust, and a distant unknown rival can become relevant through regional events. A named NPC is not necessarily significant simply because they exist.

Significance can diminish, reducing ongoing personal-event attention when the character is no longer salient. This **does not erase the character**: their stable identity, past actions, relationships, commitments and historical consequences persist and can become relevant again. Being absent from the active cast must not erase or evade unresolved consequences involving important player investments.

Reject both a permanently preselected important cast and simulating personal developments for every named NPC. The active cast remains bounded; precise prioritisation, resource limits and reactivation triggers are future implementation decisions, not fixed numbers in this ADR.

**Open decisions:** which personality/disposition model and stat mappings express contextual choices, how contradictory reports are evaluated, and how players learn about off-screen changes. No NPC AI implementation or scheduling cadence is authorised by this ADR.

## Sparse relationships between significant NPCs — accepted 16 October 2026

**Significant NPCs may form, retain and change meaningful relationships with one another**, not just with the Party. Family bonds, friendships, rivalries, loyalties, debts and obligations can matter to decisions, situations and later opportunities even when neither participant is recruited or currently visible. A village guard's ties to a criminal sibling or a rival commander can influence events independently of player interaction.

Persist only **consequential connections**: ties that credibly affect a choice, eligibility, access, allegiance, resource or future callback. This is a **sparse social network**, not a fully populated matrix of opinions or continuously changing affinity values for every named NPC. Being significant does not require recording every friendship or casual acquaintance. A relationship can be directional or asymmetric where appropriate; a debtor's obligation need not imply equal reciprocal affection.

A significant change to a relationship requires a meaningful event or a justified decision by the participants, with durable history. Passive absence should not erode ties by default. Relationship effects must respect the previously accepted distinction between world truth, conveyed information and player knowledge; this decision does not confer automatic knowledge of an event on every friend of a participant.

Reject party-centred relationships only, which would undermine independent lives, and reject an all-NPC social simulation, which would expand beyond the bounded event model. Exact relationship strengths, conflicting evidence and credibility assessment, competing obligations and conflict resolution remain open design questions. No relationship engine is implemented by this record.

## NPC information, belief and relationship changes — accepted 16 October 2026

**NPCs must react based on information they plausibly possess or believe**, rather than immediately responding to hidden World Events. An NPC can personally witness an action or receive evidence, rumours, correspondence or accounts through credible in-world channels. Such information may be delayed, unreliable, incomplete or false; what the NPC believes is distinct both from authoritative Playthrough truth and from what the Party knows.

A relationship, loyalty or local reputation may change when a relevant NPC interprets information consistent with their knowledge, prior commitments and motivations. For example, a captain does not automatically condemn the Party for a secret prison escape they could not know about. Later rumours may make the captain suspicious, and credible evidence may change their judgement. NPCs may also act on a mistaken belief; correcting it may require investigation, diplomacy or new evidence, not rewriting the original event.

Do not broadcast actions to all related NPCs or every faction in a global reputation cascade. Information follows plausible witness/report channels and audience boundaries. This does not require continuous surveillance, per-NPC courier movement or an exhaustive epistemic simulation: consequential knowledge updates can be resolved at bounded event boundaries while retaining causal history and save/replay determinism.

Rejected: **only firsthand observation**, which precludes meaningful rumours and indirect reputation; and **automatic opinion propagation**, which contradicts secrecy and the existing separation of world truth and character knowledge. Exact belief confidence scales, deception adjudication and evidence-resolution rules remain open.

## Contextual choices with bounded uncertainty — accepted 16 October 2026

When an NPC's important commitments conflict, select plausible options using their established motives, duties, relationships, **NPC Beliefs** and immediate circumstances. Do not impose one universal priority ordering for every character or substitute unrelated mood swings for causal behaviour. If the evidence strongly supports one action, the NPC can choose it without a random check. **If several plausible options are genuinely contested, a bounded, context-weighted roll may resolve the uncertainty**, with the resulting choice becoming persistent Playthrough history.

Personality dispositions, strength of obligations, trust, fear, stakes and available options may shape such a check. Existing RPG abilities can affect **how** a character perceives a risk, assesses options, maintains resolve or executes an attempt. For example, Wisdom can support situational judgement, but **Wisdom is not a measure of kindness, morality, filial affection or loyalty**. Do not make a single ability score automatically dictate whom the NPC loves or betrays. Compromise options, such as negotiating a sentence instead of choosing either obedience or rescue, can arise from skills and circumstances and may have separate success checks.

A consequential roll must be authoritative, bounded and reproducible: one resolution per event, with inputs, result and causal consequences retained across save/reload. Use the campaign's existing deterministic resolution and persistence boundaries; do not add an independent NPC dice engine or reroll on inspection, revisits or UI reopening. Player-visible explanations can describe motivations and circumstances without revealing hidden beliefs or the exact random draw before it resolves.

The specific disposition model, influence weights, mechanical ability/skill mapping and dice expression are **not yet decided**. This acceptance is about the *decision principle*, not approval of a new set of personality stats or balance numbers.

## Consequences and unresolved dependencies

- World Situations and their consequences belong to an individual **Playthrough**, not the immutable **World Template** (see ADR 0001).
- Changes must remain compatible with stable entity identities, saved history and **Player Knowledge**. Off-screen truth is not automatically revealed to the player.
- Simulation must be bounded enough to advance reproducibly across elapsed in-game time and saved/reloaded campaigns; this records an **outcome requirement**, not an engine, queue or event-sourcing implementation.
- **Still to decide:** precise criteria and capacity for activating/retiring tracked situations; advancement timing and conflicts, communication delays and report reliability, the limits/communication of delegates' mandates, specific salience-prioritisation rules for NPCs, evidence credibility and relationship conflicts, NPC motive weighting/dice mappings, available remote tasks/costs, and how requests conclude when messages are late or missing. Neither a scheduler nor a threshold is prescribed here.
- No new gameplay system or character-programme reprioritisation follows automatically from this design decision.
