# Final synthesis — build depth, lived history and a world that remembers

**GAME-87 • research/design proposal • 8 October 2026 (Asia/Shanghai).** Continues the original pre-study on `research/game-87-rpg-inspiration-synthesis`. Inputs are pinned in [SOURCES](SOURCES.md). GAME-32, GAME-86 and production gameplay are unchanged. This package proposes future contracts; it does not claim a playable Character Life system or completed player study.

## Recommendation and the difficult question

The combination can form one coherent game **if Character Life changes opportunities, relationships and consequences around deliberate builds rather than becoming a competing advancement economy**. Adopt it as a major pillar. Start with a small causal loop: an existing character contributes to an expedition, a choice leaves a structured fact, and a later opportunity responds to that fact.

The thesis is not validated merely because the inspirations fit a diagram. Deep builds reward predictability; emergent injuries and transformations threaten it. A persistent generated world can fail to contain the mentor/site a story needs. A three-person party can collapse when one hero is disabled. Every new life source multiplies rules, body, information and save interactions. Twenty-four templates can still be repetitive if their outcomes are interchangeable. Those are credible failure modes, not details to wave away.

The architecture is compatible with the current game: stable character IDs, separate immutable world and playthrough state, ordered advancement, typed rules effects, immutable snapshots and transactional saves are appropriate foundations. The largest costs ahead are **content combinations and consequence legibility**, not inventing a new class calculator. The correct response is staged implementation and falsifiable prototypes, not shipping every interesting reference mechanic.

## Why the combination earns its complexity

A former mason notices how a ruin can be breached. The player chooses to use that knowledge, records who contributed, and carries a named preparation into an encounter. Later the same character meets someone connected to that workmanship, gaining a workshop contact or personal-hook lead. Their Roadwarden/Wayfinder progression remains a deliberate separate choice. World, background, tactics and future access each do one job, joined by recorded evidence.

Compare three alternatives:

| Option | Advantage | Failure / decision |
| --- | --- | --- |
| Pure deep-build tactical RPG | Less life-state/content QA; clearer progression | Generated towns/backgrounds risk being interchangeable wrappers. Keep this as a viable core loop, but it does not realize the accepted identity |
| Light-class emergent-life RPG | Easier transformations, fewer equipment/progression conflicts | Would discard the accepted deliberate multiclass/prestige goal and GAME-32's useful foundation |
| Full simulation of careers, corruption, family, injury and legacy immediately | Broad apparent possibility | Unaffordable interaction matrix, sparse content and maintenance burden; reject |
| Staged causal Character Life over deep builds | Reuses current owners; adds remembered choices and earned access | Recommended. Must pass both uniqueness tests and protect viable builds before adding severe consequences |

Adding more classes cannot by itself answer “why did we investigate?” or “why do I care about this particular scout?” More procedural prose cannot repair the absence of a causal fact. Character Life is worth early attention once tactics work because it makes the generated setting and persistent people consequential. That does not justify postponing GAME-33 to write a universal story engine.

## Wildermyth: memorable characters versus transferable machinery

The focused source pass inspected developer-hosted writing/story documentation and gameplay wiki pages ([W1–W12](SOURCES.md)). It supports a specific chain: generated history leaves queryable aspects/hooks; a template casts suitable heroes and site; a choice changes structured state; future scenes recognize those changes. The writing guidance explicitly favors dramatic visible consequences that are mechanically simple.

| Mechanism | Why it works | TRHGD decision / complication |
| --- | --- | --- |
| Generated history and personality | A hero arrives with context; voice and role selection keep scenes specific | Preserve world-backed facts, two voice tendencies and optional motivation. History prose cannot manufacture authority |
| Aspects and hooks | Facts become future eligibility rather than forgotten flavour | Versioned salient facts; two hooks plus optional third, with real or explicitly unknown referents |
| Personal opportunities | A particular hero and helper matter to a particular story | Small deterministic arcs from existing facts. Do not require a rare helper/site combination for every quest |
| Relationships | Shared events and visible bonds explain attachment | Typed directed edges plus coarse strength; story/helper roles first, optional costed protection later |
| Event targeting | Good casting makes one skeleton feel specific | Validate a complete cast; reject impossible references; allow authored optional-role variants |
| Repetition suppression | Recent events become less likely; unique events stay memorable | Campaign-local family/actor/template memory, hard cooldowns, no reward farming; defer profile-wide weighting |
| Mortal choice and maiming | Survival changes a hero rather than only erasing one | Test rare serious consequences after treatment/substitution exists; no automatic maiming at0HP |
| Themes/transformations | Appearance, abilities and story change together | Rare staged choices, body/equipment conflict preview and source-grant removal; art and QA have real cost |
| Retirement and long campaign time | A life has stages, successors and an ending | Explicit later roster roles. Do not import chapter decades before the game's time/expedition cadence is known |
| Legacy | Reusing a hero preserves emotional memory across tales | Within-playthrough memorials/mentoring first; world-specific export later; no unreviewed cross-campaign power transfer |
| Site/campaign events | The location and campaign state become part of a personal story | Bind actual generated refs and campaign deltas; never rewrite a world template to make a scene eligible |

Wildermyth's smaller class framework and specialized visual/content tools make frequent theme swaps more manageable than in a deep multiclass/equipment system. Its relationship combat bonuses can be significant; copying them would add an optimization layer beside every class choice. Its own hook documentation lists permanent eligibility conflicts. TRHGD should learn from that limitation and provide alternative clues/helpers/remedies rather than promise every hook can always resolve in every world.

The emotional mechanism is **specificity + agency + persistent consequence + callback**. It does not require routine stat inflation, romance damage bonuses or a random permanent transformation every chapter.

## D&D/PF breadth as an architecture lesson

GAME-88's broad catalogue is useful because it exposes distinct extension mechanisms, not because TRHGD should reproduce its scale. Base classes and multiclassing are deliberate ordered choices. Prestige adds explainable entry and continuation conditions. Alternative features/substitution levels are controlled replacements, avoiding near-duplicate classes. Racial-paragon ideas fit optional heritage investment; bloodlines fit inherited latent potential rather than another mandatory levelling currency.

Acquired templates preserve an existing person while changing capabilities. Grafts need body/equipment provenance; symbionts need an entity/bond in addition to attachment. Aberrant/draconic-style feat chains suggest chosen investment after an acquired seed. Traits can memorialize consequence, but feat-for-flaw exchange encourages farming. Curses, corruption, mutation, pacts and afflictions share lifecycle/audit machinery while requiring distinct typed payloads.

The crucial rule is temporal: a life fact can qualify a future deliberate choice, but removing it later must not invalidate the fact that the choice was legal when made. [Character Life §8](CHARACTER-LIFE-CONTRACT.md#8-qualification-history-entry-continuation-and-current-use) specifies receipts with source evidence, pins and entry/continuation/current-use policies. A cured graft-linked character keeps earned levels; a capability needing that graft may stop only under its explicit current-use rule.

## Warhammer: consequence without a second job

The accepted GAME-88 synthesis supplies WFRP, Dark Heresy, Black Crusade and Imperium Maledictum context. Fresh publisher material verifies WFRP's competing downtime/income/status concerns and Imperium Maledictum's Patron, faction Influence and investigation-to-confrontation structure. Some old FFG links now return404 or a generic news index; those edition-specific claims remain inherited research, not freshly read primary rules.

| Lesson | Fit | Limit / decision |
| --- | --- | --- |
| Occupation/career can change because fiction changes | Strong: a guard, teacher or guild officer has contacts/access/duties distinct from class | One simple appointment, no second class tree or compulsory job grind |
| Ambitions and scarce Endeavours | Strong: attention/time can matter more than money | Two elective opportunities in one downtime window, routine recovery automatic; no daily chore list |
| Status and responsibility | Strong: an office grants access and obligations | Sparse audience-specific standing, not universal fame; service demands are bounded |
| Critical injury and fate-like survival | Strong but dependent on recovery/roster | Compare models after combat; no imported critical table or locked final death model |
| Immediate fear, aftermath trauma, supernatural corruption | Strong conceptual separation | Contextual rare lasting responses; no universal sanity meter, alignment change or mental-illness caricature |
| Corruption as tempting power/risk | Useful later | One domain/stage prototype, opportunity costs and clean alternatives; no mandatory multi-meter optimization |
| Mutation has bodily and social consequences | Strong | Local observed reactions vary by culture/faction; anatomy never sets morality |
| Pacts and dangerous magic | Good authored exceptional decisions | Compelling need and explicit cost; overchannel is later costed content, not random ordinary-casting punishment |
| Disease, augmetics/prosthetics | Useful connection to facilities and recovery | Typed stage/attachment systems; no organ simulation or constant save-until-cured chore |
| Patrons, boons/liabilities and Influence | Good later optional social agreements | No mandatory starting Patron, universal Influence resource or copied oppressive setting assumptions |
| Investigation creates confrontation advantage | Highest-priority transfer | Typed preparations/evidence with contributor/expiry; do not just add a generic damage buff |
| Hireling quirks/work ethic | Useful after roster growth | Negotiated roles/availability, not random uncontrollable combat AI |

Trauma and corruption remain independent. Corruption's bodily/psychic channels may be separate symptoms before becoming separate numeric tracks; only add a meter if it supports a distinct player decision. A broad “acquired state” is valuable as a common envelope and transaction protocol, but a giant untyped record would hide errors. Use a versioned discriminated union of wound/trauma/curse/corruption/mutation/graft/symbiont/pact/disease/transformation payloads.

## Other references, only where they resolve an open question

Wasteland and Wasteland2 demonstrate party capabilities beyond combat classes and making the selected contributor matter. Use those lessons to credit the actual investigator and expose their concrete payoff. Gloomhaven shows that costly powerful choices and scenario objectives can matter across an expedition; retain persistent resources without importing card exhaustion. NWN2 Enhanced Edition confirms that deep 3.5-style character construction remains a useful deliberate-build reference, not an alternative combat scheduler.

Stolen Realm supports cross-path build freedom but its simultaneous team turns would change the GAME-86 problem. Sunderfolk's mission guide and role presentation support readable choices, while its party-order flexibility is not adopted. Rogue Trader's official beta guide distinguishes movement/action resources and explicitly bounded attack exceptions; its extra-action/Momentum complexity is a warning to make every exception visible, not a reason to add another resource stack.

## Concrete architecture decisions

1. Keep identity, build, social position and lived history distinct, joined by stable references and provenance. Culture is not ancestry, occupation is not class, and prose never owns state.
2. Keep creation small: confirm identity/origin/background/motivation and one recommended legal first build. GAME-81 Vanguard/Scout/Adept/Expert remain recommendations; advanced choices remain available. Two hooks and one optional starting bond seed play; future curses/prestige/careers are not creation tabs.
3. Persist sparse life facts and audited changes in the playthrough. A source-aware grant ledger produces generic mechanics; class history is never directly rewritten by an event. Missing content pins fail explicitly.
4. Use deterministic declarative casting, family/actor event memory, and atomically saved offers/choices/results. Prose variants render after authority decisions. Known risks and meaningful remedies must accompany major consequences.
5. Use scoped reputation, optional occupation/patron agreements and limited downtime. Do not simulate every profession, duty or faction relation simultaneously.
6. Make investigation useful through knowledge and encounter inputs: alternative deployment, known hazards, costed preparation, breakable structures, sabotage, suspected illusion or dialogue. Separate information from physical truth.
7. Add severe injuries only with a viable recovery/adaptation path. Preserve stable identity and deliberate investment through body changes. Do not lock the death/fate model before matched encounters and player feedback.
8. Use historical qualification receipts for life-gated prestige. Separate entry, continuation and present use. Losing a mentor/source later cannot delete a legal past level.
9. Keep one tactical engine and one payment authority. Extra strikes, restricted tokens, movement, reaction capacity, extra Main and rare extra turns are different declarations within it. Explicit scope/expiry/stacking/caps prevent loops.

## Combat clarification and present action

GAME-86 selected movement + Main + shared Reaction with fixed initiative as the baseline. The accepted direction explicitly permits future exceptions. Multiple strikes in one Main fit two-weapon attacks, fighter progression, flurry or multi-limb techniques without adding a turn. A restricted token permits a named bounded option; an extra Main can multiply the best spell and therefore needs stronger constraints. Extra turns must not recursively mint turns or refresh every normal-start effect.

[GAME33-IMPACT](GAME33-IMPACT.md) gives one command/payment model, sequence cancellation/retarget policy, source/stacking/expiry, refresh boundaries, loop caps, same-engine AI and save/replay tests. It recommends testing a future +2 stride/single-strike Haste, with movement-only Haste as a comparison. Those are unimplemented prototype values. Current Slow stays−2 stride/minimum1, and no new generic swift/bonus currency is added.

[GAME32-IMPACT](GAME32-IMPACT.md) found **no blocker requiring identity/progression rewrite**. V1 already provides generic runtime features, tags, modifiers, senses, resource separation, requirements, immutable snapshots and transactions. It does not yet provide source-specific grant revocation, rich body/item allocation, life qualification receipts or extended action costs. Plan reviewed schema extensions before those dependent features; do not modify or reopen GAME-32 now.

## Proof, uncertainty and rejection criteria

[PROTOTYPE-PLAN](PROTOTYPE-PLAN.md) defines24 event templates:16 initial core stories and8 advanced schema probes, each with eligibility, choices, outcomes, callback and repetition policy. The first production slice activates core templates only. Advanced injury/corruption/curse/mutation/downtime/body/pact/disease/symbiont cases exercise the design on paper and later harnesses; they are not covert V0 production scope.

Two counterfactual tests are mandatory. Identical builds must become distinguishable after ten expeditions through choices, relationships, opportunities and remembered facts. Similar histories must still permit mechanically distinct deliberate builds. The provided ten-expedition trace and comparison are **designed tests, not empirical passes**. Future engineering tests establish determinism/correctness; small formative human tests must establish meaning and tolerable complexity.

Reject or narrow individual systems if players see only cosmetic callbacks, events routinely lack viable casts, optimal play demands romance/corruption farming, or recovery/duties make expeditions feel like chores. Do not respond by adding hundreds of events, arbitrary narrative bonuses or more meters. Preserve the core and fix the causal links. Toy AI win rates cannot establish emotional value, encounter usefulness or acceptable permanent-loss pressure.

## What follows and what does not

- **First implementation:** after the combat foundation, additive life facts, directed relationships, motivation, two hooks, declarative event targeting/memory, atomic offers/results,16 core templates, one two-stage personal arc, contributor-labelled investigation evidence and a narrow encounter-preparation bridge.
- **Wait:** downtime/occupation/standing, recoverable consequences with treatment, then selected acquired-state arcs, qualification-backed prestige, body replacement, transformations and expanded roster roles. Move each schema prerequisite before its first dependent mechanic.
- **Never build as proposed:** universal reputation/morality/sanity; ancestry-driven morality; class=occupation; flaw/relationship reward farming; forced random class levels; arbitrary script/prose authority; a second autoresolve engine; unbounded recursive actions/turns; routine organs/daily-social-maintenance simulation.
- **GAME-33 must preserve now:** sequence-ready actions, one normalized payment authority, explicit clock boundaries, source-grant extension seams, observer knowledge, encounter preparations and idempotent aftermath results. Shipping all exceptional abilities now is unnecessary.
- **Future GAME-32 extensions:** grant ownership/removal/pool retention; qualification receipts and phase policies; body/item capacity; normalized extended costs/sequences; life-composition pins and controlled feature replacement. None blocks acceptance of the completed V1.

The full prioritization and explicit NO ACTION NOW / GAME-33 / future life / future schema / future content / reject classification is in [ROADMAP](ROADMAP.md).

**Final verdict — A. Adopt Character Life as a major pillar of TRHGD.**
