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

The player is free to ignore, defer or decline intervention. Protection of the hometown is not mandatory, and consequences are not suspended merely because the Party travels elsewhere. An intervention may change the severity or beneficiaries of an outcome without preventing the underlying event. Warnings should convey actionable stakes rather than perfect information about the hidden world; how information arrives is an unresolved downstream decision. Serious unforeseen events elsewhere may still occur.

Reject automatic protection of all important possessions and relationships: it makes off-screen threats toothless. Reject unrestricted, unheralded destruction of personally meaningful things: it makes the simulation feel arbitrary and punishes exploratory freedom. No fixed grace period, notification system, minimum rescue chance or numeric escalation schedule is decided by this record.

## Consequences and unresolved dependencies

- World Situations and their consequences belong to an individual **Playthrough**, not the immutable **World Template** (see ADR 0001).
- Changes must remain compatible with stable entity identities, saved history and **Player Knowledge**. Off-screen truth is not automatically revealed to the player.
- Simulation must be bounded enough to advance reproducibly across elapsed in-game time and saved/reloaded campaigns; this records an **outcome requirement**, not an engine, queue or event-sourcing implementation.
- **Still to decide:** precise criteria and capacity for activating/retiring tracked situations; how frequently they advance, how competing effects resolve, the in-world channels and timing by which warnings reach the player, and how response opportunities are kept meaningful without guaranteed safety. Neither a scheduler nor a threshold is prescribed here.
- No new gameplay system or character-programme reprioritisation follows automatically from this design decision.
