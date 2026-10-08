# GAME-33 impact — extensible budgets within one combat authority

**Preserve now; implement only in GAME-33's own scope.** GAME-86's baseline remains one movement allowance, one Main, one shared Reaction, fixed individual initiative. It is a baseline, not a permanent ceiling. This document refines future extensibility without modifying GAME-86's research or GAME-32 V1. A reviewed rules-schema change must precede shipping content that V1 cannot represent.

## One normalized command/payment model

Internally GAME-33 should reason about **actions and ordered effects**, not assume “one action equals one attack.” An ability declares a payment and a finite resolution program. A normalized baseline payment consumes its Main/move/reaction/resource requirements once. Existing V1 definitions translate losslessly; no new capability becomes legal just because the adapter exists.

```text
ActionDefinitionVNext:
  definition_ref, eligibility, targeting, payment, resolution_sequence
  usage_limits, timing, interruption, observation_policy

Payment:
  required_pools[], alternative_action_authorizations[]
  resource_costs[], chosen_authorization_id

BudgetState:
  encounter_id, actor_id, normal_activation_id, activation_family_id
  round_id, movement{remaining,segments}, main_remaining
  shared_reaction{capacity,remaining,refresh_round}
  grants{grant_instance_id: RestrictedAuthorization}
  usage_counters, pending_sequence?, pending_prompt?, revision

RestrictedAuthorization:
  source_ref, issued_at, expiry_boundary, count, family_limit_key
  allowed_action_ids/categories, max_strikes_per_use
  may_pay_resources?, may_grant_actions(false default)
  stacking_group, replacement_policy, consumed_count
```

An authorization may replace a Main cost for an eligible action; it does **not** remove that action's Focus/technique/equipment/target requirements. Ordinary Main remains available for that action unless its definition requires the special token. The command names the chosen payment source; validator confirms ownership/eligibility and commits the cost once. Do not spend both Main and restricted token accidentally. Compound Dash/Charge still require both ordinary components unless a specifically reviewed grant authorizes the compound cost. `StrikeOnly` never pays for Dash, a spell or an entire multi-strike package merely tagged “attack.”

There must be **one payment authority shared with the rules executor**. When extending V1, replace/extend its cost execution boundary with a reviewed normalized transaction interface and compatibility adapter. Do not forge a synthetic `main=1` budget to trick `use_ability`, patch an actor's resource twice, or add a narrative-only bypass. Low-level numeric/effect primitives remain reusable; authority snapshots/definitions are the inputs for humans and auto alike.

Public legal options enumerate permitted actions and payment sources from an observer view. Hidden geometry/target truth cannot be used to provide free legality probes. An attempted perceived-target interaction pays its cost before revealing a contradiction according to the existing GAME-86 illusion contract.

## Distinguish seven kinds of exception

| Kind | Representation | Recommendation / limit |
| --- | --- | --- |
| Extra strikes inside one Main | Finite ordered attack steps after one payment | Natural two-weapon/multiweapon model; no new activation |
| Progression attack sequence | Features choose a reviewed Attack package | Fighter extra attacks and flurry need not require standing still; sequence length/cost is data |
| Restricted action token | One named authorization matching explicit action IDs/category and strike cap | Haste/action-surge-like/special anatomy options; not generic swift action |
| Extra movement | Movement allowance modifier or bounded MoveOnly authorization | Distance and segment permission are separate; increased stride alone never splits baseline movement |
| Reaction budget modifier | Change the capacity of the same shared pool with provenance | No private Guard/relationship/limb reaction pools |
| Rare extra Main | Explicit bounded grant with source/cost/expiry | High opportunity cost because it can repeat the actor's best spell or feature |
| Extremely rare extra turn | Scheduled extra activation with parent/family identity | Deferred content; no speed-derived frequency and no recursive turn grants |

Proposed initial extension **content caps for prototype testing**, not final balance: at most4 strikes in one paid sequence, one restricted authorization per normal activation family, at most2 Main spends in that family, shared reaction capacity at most2 per global round, and at most1 extra activation per actor per global round. Baseline content grants none of these extras. Every cap change is a rules-version decision, not a silent clamp. Technical safety bounds (for example max64 resolution events per command and bounded prompt/trigger depth) are separate: an overflow produces an explicit aborted/invalid transaction and diagnostics, never a fabricated successful combat result.

## Sequences, weapons and interruption

A Twin Strike concept spends Main once, then resolves main-hand and off-hand strikes with declared accuracy/damage, weapon-instance refs, target policy and per-strike counterplay. Fighter progression can select a two-strike Attack package; flurry can use a distinct resource/cost/accuracy package. Do not simultaneously concatenate every eligible package. Composition policy chooses one base sequence plus compatible bounded riders, sorted by stable source/step order.

A sequence defines fixed targets or a declared retarget window. If the first strike downs a target, later steps fizzle or prompt for a new permitted target according to that policy. They do not silently refund Main or retarget hidden enemies. Costs pay once; RNG advances only for actually resolved rolls in canonical step order. Every damage/hit/after-hit/reaction/death check has a step index and causal parent ID. Save/reload can resume a pending reaction between strikes without repeating earlier damage.

Baseline movement is one contiguous segment before or after Main. A future “strike, move, strike” technique must explicitly allow an interleaved movement segment and use the same occupancy/departure rules; an extra limb does not grant it by implication. Two-handed grips, shields, tools, natural attacks and grapples consume validated body/equipment capabilities. GAME-32 future body/schema support determines availability; GAME-33 sees an authorized attack package, not a mutation-specific branch.

Precision remains **+4 on the first qualifying hit per normal activation family**, not on every strike, attempt, reaction or extra activation generated from that family. A miss does not consume its first-hit opportunity. Event-scoped modifiers never leak into persistent character damage. Any future exception to that once-per-family scope must be an explicit versioned feature, not an accidental consequence of a new action token.

## Haste, Slow and time boundaries

Sources [D1/P1](SOURCES.md) verify that ordinary 3.5/PF1 Haste adds an attack within full attack plus other benefits; it does not supply unrestricted extra casting. TRHGD may choose a clearer original form.

**Recommended first future Haste experiment:** +2 stride and one `StrikeOnly` authorization for a single ordinary weapon strike, expiring at that target's normal activation end, refreshed only at its next normal activation start while the effect remains active. Use the normal resource/target rules; no casting, no multiattack package, no action-granting ability, no extra movement segment from that token. Compare it with movement-only Haste before accepting its damage economy. Duration/cost/save/range are content research still to do, not defaults secretly added to GAME-32.

`MoveOnly` and `TechniqueOnly` remain supported categories for later experiments. TechniqueOnly needs an allow-list of bounded techniques; broad tags alone must not admit future unbounded capstones. A stronger time spell can grant an extra Main through the same system, at a higher explicit cost. Extra turns remain later still.

**Slow keeps GAME-32 V1's −2 stride/minimum1 policy** initially. Do not strip Main or cancel Haste just because another game's Slow does. A future action-denial variant must declare which unspent authorization it removes, its expiry and counterplay, and test the harsh effect on a three-person party. Never retroactively reclaim already spent actions or produce negative remaining tokens.

Clock vocabulary must distinguish `global_round_start`, `normal_activation_start/end`, `extra_activation_start/end` and `command/strike boundaries`. The V1 `target_activation_end` and deferred `next activation` policies map to **normal** activations in the compatibility adapter. An extra turn does not prematurely expire Slow, resolve Delayed Burst, refresh Focus, restore the shared reaction, or advance life recovery clocks. A future ability can explicitly opt into another boundary only via reviewed data.

At a normal activation start: process declared start effects/pending resolutions in pinned priority order, handle incapacitation, initialize base movement/Main, then issue eligible grants once with a `(source,actor,normal_activation_id)` key. Reapplying Haste in that family cannot reissue a consumed token. Stacking group uses max/replacement, not sum, unless a specific rule says otherwise. Removal revokes unused source grants; spending then dispelling never earns a refund. Increasing reaction capacity mid-round increases the cap but grants current uses **only when explicitly declared**; repeated suppression/resumption cannot refill. Global round refresh occurs once and uses the valid current cap.

Extra turns use a queue entry after a specified stable boundary; do not reroll initiative or alter the fixed queue's normal turns. They share the originating activation-family usage limits, carry reaction remainder and get only their explicitly granted movement/Main—not a fresh application of every normal-start trigger. An extra turn cannot grant another extra turn; action-granting descendants inherit `may_grant_actions=false`. Limit graph depth, generation count and source uses, and reject cycles at content load plus runtime guard. This prevents “extra attack triggers extra action triggers extra turn” loops.

## Character Life inputs and outputs

| Life input | Authoritative boundary | GAME-33 duty |
| --- | --- | --- |
| Injury/graft/mutation | Pinned snapshot + supported body/capability projection | Use stats, equipment legality, abilities/reach/senses; never inspect biography |
| Relationship | Explicit capability/condition/target relationship ref | Shared-reaction protective option or declared technique; no automatic romance DPS |
| Corruption/curse/pact | Generic grant/status/resource with source pin | Declared costs/consequences; no spontaneous moral alignment or random control theft |
| Investigation | Encounter preparation records and observer evidence | Deployment, objects, reinforcements, known hazards/weaknesses and costed resistance preparation |
| Illusion/perception | Authority apparent effects and separate observer knowledge | No physical fake collision; same apparent handles for perceived real/false targets |
| Persistent aftermath | Idempotent result with downed/rescue/retreat/death/exposure evidence | Report facts once; campaign applies life consequences after battle |

Snapshot envelope pins build, rules, life/grant projection and current resources at encounter creation. Campaign revisions cannot mutate those participants behind the running battle; defer life changes to an accepted battle command or post-result transaction. Preparation has an encounter scope, source contributor, audience, expiry and consumption receipt. “Suspected illusion” is evidence, not permission to give AI secret physical IDs. Reinforcement sabotage changes EncounterSpec only if a committed campaign event actually did it.

GAME-34 displays budgets by purpose: movement, Main, shared Reaction and a temporary named grant such as “Haste: one weapon strike.” It previews every sequence step, known counterplay and resource cost, and marks uncertainty. GAME-35 chooses among the same commands/payment sources, with the same observations and explicit policy state. Neither may approximate a graft, curse, multiattack or investigation advantage with a private damage multiplier.

## Required GAME-33 fixtures and deferred fixtures

**Requirements to preserve in the first implementation:** baseline V1 adapter; a sequence-capable resolver with a one-strike production action; explicit normal/global boundaries; bounded trigger/prompt state; canonical command/effect IDs and RNG; observer-safe legal-option/preview boundary; encounter preparation envelope; atomic idempotent battle results. Include a small synthetic two-strike fixture to prove the abstraction without shipping a class feature. Keep production Haste/extra-limb/extra-turn content disabled until a reviewed schema supports it.

**Acceptance when extensions are implemented:** Twin Strike pays once and resumes between strikes; target dies mid-sequence; Precision applies only once on hit; StrikeOnly rejects casting/Twin Strike/Dash; extra movement triggers the ordinary departure rules; two sources cannot stack/refresh Haste illicitly; shared Guard/departure/protection reactions exhaust the same pool; extra turns neither refresh nor expire normal-boundary effects; cyclic grants reject; identical commands replay with rendering/manual/auto switched without changing hashes. Include hidden-information differential tests, friend/enemy targeting, already-spent grant removal and save/reload after each pending boundary.

No GAME-86 win rate is evidence for any proposed grant cap or Haste value. These fixtures prove legality/reproducibility; protected ranged positions, objectives, class opportunity costs and human readability still need actual combat evaluation.
