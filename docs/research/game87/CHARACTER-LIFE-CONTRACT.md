# Character Life contract — proposed schema and ownership

**Research contract, not implemented.** Names below are proposed interfaces, not callable GAME-32 APIs. The finished V1 rules source remains pinned to `5caa55f0ea515d57b75c00b8ccbfac17e41948af`. [GAME32-IMPACT](GAME32-IMPACT.md) identifies every required future extension.

## 1. Authority and persistence

| Owner | Owns | Must not own |
| --- | --- | --- |
| GAME-7 world/template store | Immutable geography, original settlement/site IDs, world pin | Playthrough injuries, reputation or changing a template to make a quest fit |
| GAME-81 identity/party | Stable characters, established names/people/origin/background and roster references | A replacement identity generated from a rules class |
| Character Life | Aspects, hooks, directed social edges, acquired-state instances, qualification evidence, life history | Recalculating class statistics or executing tactical attacks |
| Campaign/expedition transaction owner | Clock, world deltas, facilities/factions/patrons, event offers/receipts, encounter preparation and result application | A second independent save commit for each life subobject |
| GAME-32 | Rules definitions, ordered build validation, generic grants/effects, immutable mechanical derivation | Reading prose, querying live towns during historical replay |
| GAME-33 | Battlefield authority, observations, action budgets, result facts | Advancing life stages or choosing a permanent injury during an attack animation |

Propose an additive `character_life` campaign section, keyed by the **existing character_id**, plus campaign-wide relationship/reputation/event tables. World IDs are `(world_pin, entity_kind, entity_id)`; dynamically created campaign NPCs/facilities receive `(playthrough_id, entity_kind, id)` and never masquerade as template entities. Character identity survives transformation, occupation change, retirement and death; dead/removed entities are tombstoned so evidence does not dangle.

```text
CharacterLifeV1:
  schema_version, life_pack_ref{pack_id,version,content_hash,engine_schema}
  revision, migration_receipt, characters{character_id: LifeRecord}
  relationships{edge_id}, standings{standing_id}, grant_ledger{grant_id}
  qualification_receipts{receipt_id}, history{sequence: LifeDelta}

LifeRecord:
  character_id, revision, motivation_ref
  short_ambition?, long_ambition?, hooks{instance_id}, aspects{instance_id}
  acquired_states{instance_id}, current_occupation?, duty_refs[]
  roster_status, body_ref?, knowledge_refs[]

Instance envelope:
  instance_id, definition_ref{pack_id,version,content_hash,id}
  subject_id, source{event_receipt_id,actor_id?,world_ref?,parent_instance_id?}
  acquired_at{campaign_tick,sequence}, state_revision, visibility_ref
  status(active|suppressed|resolved|removed), removed_at?, reason_code?
```

IDs are stable opaque identifiers minted once by the transaction owner from persisted campaign identity/sequence and a pinned namespace algorithm. Names and array indexes never serve as identity. Definitions own tags, conflict sets, mechanical references, presentation templates and allowed transitions. Instances store typed parameters and current stage; they do not embed editable rule programs. Unknown fields/operators/definition versions reject with a path and code. Proposed bounds: 32 active salient aspects, three active hooks, one short and one long ambition per hero in the first slice. Overflow requires a reviewed replace/archive choice, not silent deletion. History is not capped by forgetting prerequisite evidence.

A life fact becomes an aspect only if it can affect a query, presentation, decision or later callback. “Enjoyed yesterday's stew” can remain a history sentence; “promised the cook to find her son” creates an obligation/hook. Background facts already owned by identity are referenced through an adapter rather than copied into editable `former_mason` aspects.

## 2. Aspects, grants and audit

Aspect acquisition/removal appends a `LifeDelta` with sequence, expected revision, source receipt, definition pin, before/after hashes and reason. Correcting a fact is a new amendment; do not overwrite the historical record. Definition upgrades are previewed migrations with retained old pins and receipts. A hidden aspect and a visible scar can reference the same causal event without publishing its hidden payload.

Aspects may grant mechanics, but only by referencing reviewed features/modifiers/resources/senses/abilities in the rules pack. The future bridge is:

```text
life instances -> active source grants -> validated mechanical projection
              -> GAME-32 derive -> immutable snapshot + authority hashes
```

The **grant ledger** is the authority for external grants, not a second stats calculator:

```text
Grant:
  grant_id, subject_id, source_instance_id, source_definition_ref
  rules_ref, feature_ref or effect_ref, activation_predicate_ref
  acquisition_sequence, lifecycle(active|suppressed|revoked)
  retention_policy, resource_pool_key?, provenance
```

Two sources granting the same feature must remain two ledger entries. Derivation can deduplicate a nonstacking feature, but removing one source cannot remove the other or erase a class-granted feature. Modifier stacking stays GAME-32 policy; source identity does not bypass typed stacking. Reconciliation is idempotent and owns only the external projection it generated, preserving class, equipment and battle-owned state. General revocation/suppression and provenance require a future rules schema: V1's bare `runtime.granted_features` strings are insufficient.

Current HP/resources are mutable facts, never reconstructed as “full” on a new derivation. Adding capacity preserves spent amounts and initializes a newly external-granted pool at zero unless an explicit acquisition reward says otherwise. Suppression retains a tombstoned pool balance; restoration clamps that balance to current capacity and does not refill it. Removing capacity clamps current values with a visible event. Reacquiring the same source cannot farm healing/resources. Permanent removal/replacement publishes the exact pool disposition. V1 advancement's existing new-pool policy remains unchanged in its own version.

Preview removal checks dependent prepared abilities, equipment, body occupancy and current-use conditions. It lists lost options and routes incompatible gear to owned inventory atomically; it never destroys the item or rewrites earned class levels. Clamp HP to a reduced maximum without free healing. An involuntary injury may force an equipment transition, but the declared consequence includes a usable fallback and recovery route before content is approved.

## 3. Relationships

Use **typed edges plus coarse directed strength**, not one romance/friendship number per pair. Edge fields: `edge_id, from_id, to_id, type, strength(0..3), agreement_ref?, source_receipts[], visibility, active`. Prototype labels: known, trusted, close, defining. Debt/oath/mentor/student are directional; a reciprocal friendship or romance consists of two explicit edges linked by one agreement. Family is a distinct structural edge and is not inferred from surname/ancestry. Compatible types can coexist; mutually exclusive types and relationship changes require declared policy.

Growth requires a meaningful shared outcome or player choice with a unique evidence receipt; merely replaying an easy fight is not growth. At most one positive strength increment for the same pair and event family per expedition. Routine absence never drains a meter. Betrayal can change an edge explicitly, with attribution and knowledge boundaries. Romance is optional and is never a better mechanical reward tier. Events target direction/type/strength and co-presence; an off-site mentor is allowed only when the trigger supports remote contact.

V0 uses relationships for casting, help, and callbacks. Later choose one restrained expression: a protective option consuming the **existing shared reaction**, rescue behavior under player tactics, recovery assistance, or a coordinated technique with normal cost. Evaluate alternatives before adding them together. No percentage damage multiplier, mandatory pairing, automatic ally suicide or hidden second reaction. AI receives the same permitted bond-derived options; the player can decline them.

## 4. Motivation, ambitions, hooks and personal quests

Motivation is a revisable preference anchored to identity; an ambition is a desired outcome; a hook is unresolved evidence/problem. Each has its own ID and lifecycle. An ambition is not an automatic XP task. Generate two initial hooks, optional third, with referents that exist or explicitly say “identity/location unknown.” Never invent a dead parent as objective truth from a prose generator.

Hook state machine: `latent -> available -> pursued -> resolved | abandoned`; a suspended hook retains progress/reason and can resume. New evidence can branch it through a recorded transition; a resolved hook remains in history and cannot be farmed by reacquiring its seed. An abandoned path may yield a different persistent fact, not an unexplained reset. Completion can create a nonmechanical aspect, contact, training opportunity or qualification evidence. It never assigns a prestige level without the player's advancement choice.

Quest eligibility binds **character + unresolved hook + relationship/helper if relevant + actual site + optional facility/faction + campaign state**. Example: a former miner with a missing-mentor hook, a trusted available helper, a discovered accessible abandoned mine, and a surviving clue can receive a search lead. Do not secretly convert the closest mine into the mentor's location: campaign truth must already bind it, or a new authoritative clue transaction must establish a consistent candidate. Require helper only if the authored scenario uses one; offer solo/contact variants so generated worlds cannot strand every hook.

A two-stage personal hook payoff belongs in V0; a general quest planner is later. A missing facility yields a clear blocked lead or alternative route, never a fabricated settlement. Procedural generation proposes a cast/site; it cannot solve a contradiction by rewriting world facts.

## 5. Occupations, downtime, standing and patrons

Background records the past; a current occupation is an appointment with `organisation_ref, role_definition, start_sequence, access_refs, duty_refs, exit_conditions`. Mason's apprentice / Roadwarden4-Wayfinder2 / caravan guard is legal. No parallel career XP tree. Taking/leaving a role follows fiction and a recorded agreement; access and duties change while build history remains intact. Possible benefits are contacts, bounded income, training/facility access and event eligibility. Social rank is an explicit local office or recognized status, not wealth converted to universal respect.

Prototype V1 downtime: **one seven-day window and two elective opportunities per participating hero** after a meaningful expedition. The campaign advances seven days once, not seven per character; the days/opportunity counts are proposed tuning. Activities require time + opportunity + access, optionally a resource/favor. Routine rest/recovery can proceed in parallel without a menu tax. Treatment, training, hook investigation, research, work, role service, repair/crafting, relationship care, cleansing, adaptation and recruitment compete within those two slots. Offer a safe default; unused slots confer no banked future power. Passing time again advances real campaign clocks and cannot mint free limitless income. Duties consume at most one elective slot in the initial content budget; breach is a disclosed consequence, not an automatic death spiral.

Reputation/Influence uses sparse records keyed by **subject** (character/party/guild) and **audience** (town/region/state/faction/religion/guild/house/criminal group/profession). Proposed value −3..3 plus reasoned standing tags/office references. Subject scopes never inherit automatically: one hero's betrayal is not universal party guilt. Audience knowledge requires witness/report evidence. An event can atomically improve one faction and harm another; no implicit matrix propagation across every faction. Actual standing and the player's estimate are separate. Influence is access/authority, not a second fungible currency to grind.

Patrons are **emergent optional agreements**, initially one active sponsor per group, not a mandatory creation choice. A noble, merchant group, temple, council, retired hero, officer or arcane society references an existing campaign entity. Define boon/access, duty, deadline/trigger, rival exposure, exit and breach remedy. Group patronage and a personal supernatural pact can share agreement records without collapsing them into the same system. Guild-scale patron networks wait.

## 6. Acquired states: shared lifecycle, typed payloads

Adopt the common envelope, audit, visibility, stage-transition and grant-projection machinery. **Reject one untyped bag containing every possible disease, pact and limb field.** `category` selects a closed, versioned payload schema and transition policy. A category itself grants no automatic mechanic. Common optional fields are `stage_id, body_slot_refs, symptom_refs, grant_refs, restriction_refs, event_tags, suppression, removal_options`. Unused fields are absent, not loosely meaningful nulls.

| Category | Required distinct payload / behavior | Choice and boundary |
| --- | --- | --- |
| Wound | Body location if relevant, severity, treatment/recovery clock, impairment refs, scar outcome | HP loss is not a wound. First content uses recoverable impairment before irreversible loss |
| Trauma | Specific fictional trigger, aftermath response, support/recovery route | Immediate fear is a combat status; lasting trauma is rare. No corruption points, moral change or caricatured “insanity” |
| Corruption | Domain/source, exposure receipts, stage, symptom/power refs, cleansing/irreversibility policy | Exposure is not morality. Power has a declared tradeoff and clean alternative |
| Curse | Attachment (person/item/oath/site), conditional triggers, benefit/burden, escalation, clue/suppression/removal rules | Known symptoms do not imply known cause; every serious curse has an arc |
| Mutation | Body/capability change, conflicts, visible traits, stabilization and optional investment branches | Involuntary seed, player chooses cure/suppress/stabilize/embrace or later feat/prestige |
| Graft/prosthetic | Attachment/replacement, fit/capability rules, removal, side effect and crafter/event provenance | A replacement can restore a build before offering a different one |
| Symbiont | Separate entity ID, attachment, bond agreement, dependence, separation consequence | Living partner and acquired-state link; not anonymous loot or a new hero identity |
| Pact | Counterparty entity, compelling need, granted benefit, obligation/taboo, breach/severance | Saving a friend/town or curing injury can motivate it; previews do not disclose unknowable patron truth |
| Disease | Incubation/stage, symptom/treatment rules, bounded explicit transmission boundary | No per-step contagious simulation. At most an exposure event per authored travel/downtime boundary initially |
| Transformation | Staged body/grant replacement plan, required consent milestones, retained identity, irreversible threshold | Rare personal arc; preserves build history, no forced class levels or ancestry overwrite |

These share transitions `acquire -> active -> suppress/resume -> advance/stabilize -> resolve/remove`; a definition declares which edges exist and their preconditions/costs. Suppressed is not removed, resolved is not never-existed. Cycles giving net resources/grants without a finite cost reject. Transition outcomes use the event transaction, never category scripts that write saves directly.

Corruption initially needs **one domain-specific stage** (`trace`, `marked`, `changed`, plus an explicitly reviewed terminal outcome), not eight domains × bodily/psychic meters. `clean` is absence/history, not an active affliction. Bodily/psychic symptom channels may be separate lists; numerical subtracks wait for evidence that independent treatment choices need them. Terminal “consumed” must be an advertised authored consequence, not an automatic moral judgement or arbitrary player-control theft. Test one domain before adding void/necrotic/abyssal/fey/elemental/divine/blight/artifact variants.

Corruption powers use the same action/resource costs, cannot stack every domain into free power, and need an uncorrupted build route with comparable objective utility. Prestige access is an option, not a universal superior tier. Test temptation and regret alongside combat utility; toy duel win rates cannot price social costs.

Every curse template states: what is gained/risked, what new play it creates, and how to suppress/transform/remove it. Cover burden, boon-with-cost, escalating, conditional, obligation, transformative and social forms through payload data, not seven new engines. Visible mutation reactions are authored per culture/faction/locality and observed evidence: the same mark can be welcomed or feared. The simulation never infers morality from anatomy.

## 7. Minimal body model and build protection

Use stable slots for head, torso, left/right arms, left/right legs; optional named wings/tail/additional limbs only when content needs them. Each slot has `slot_id, parent?, capabilities, state, occupant_refs`; equipped objects claim capabilities/slots, not hardcoded human arm counts. A two-handed weapon requires two compatible manipulator claims. A shield, focus or grapple can claim another; adding an arm grants capacity only. Strikes require an explicit ability definition. No extra Main follows from anatomy.

Do not simulate organs, tissue layers or detailed hit locations in V0. The first body implementation needs functional/unavailable/replaced, attachment conflicts, appearance cues and equipment validation. A wing tag does not secretly enable unimplemented flight geometry. Unsupported movement modes remain unavailable with a clear content-validation error.

A major change preview shows gear moved to inventory, newly unavailable/prepared abilities, current/max resource changes, new capability options, available treatment and estimated recovery. For a planned two-handed build, offer temporary impairment + a restoring prosthesis route before approving permanent arm-loss content. Do not award a free feat for farming a wound; compensation is access to treatment/adaptation, not automatic superiority. Retraining, if introduced, has its own explicit transaction and history amendment rather than deletion of prior levels.

## 8. Qualification history: entry, continuation and current use

**Do not inject today's life tags into every past advancement step.** Introduce a future mechanical schema with a `qualification_ref` at each affected choice, and a pinned rules definition of when each requirement applies:

- `entry`: evaluated once when first entering the path/choosing the feat;
- `continuation`: evaluated for each subsequent level that explicitly requires it;
- `use`: gates present ability use or equipment fit, never the legality of an earned historical level.

Existing V1 records retain V1's precise replay semantics. Migrating them must not invent life evidence or silently reinterpret V1 requirements as entry-only. Versioned definitions and migration receipts preserve the original decisions.

```text
QualificationReceiptV2:
  receipt_id, character_id, choice_id, ordered_step_index
  prior_build_hash, rules_ref, requirement_definition_hash, policy_version
  campaign_sequence, life_revision, world_delta_revision
  evidence[]: {predicate_path, typed_value, subject_ref,
               source_receipt_or_definition_ref, valid_at_sequence}
  evaluated_context_hash, result, issuing_transaction_id
```

Trusted preview computes the exact minimal context from build + authorized life/campaign facts at the prescribed boundary. Class entry reads pre-level facts; feats retain the rules version's defined post-allocation boundary. The commit rechecks expected revisions and evidence under the campaign lock, then atomically records the step, receipt and source history. It never accepts a client-authored “qualified=true.” Hashes detect mismatch, not trustworthiness; authority is the validated transaction and pinned source evidence.

Reload replays each historical choice against its pinned historical context and evidence, not live faction reputation or a living mentor query. Retain relevant evidence values/definitions even if the world entity is tombstoned. Hash chaining alone cannot recover pruned facts: evidence required by receipts must survive compaction, and migrations retain a verifiable checkpoint plus subsequent deltas. A bad receipt fails with a structured repair/export path; do not drop requirements.

Worked example: at level5 an adept enters a future original path requiring Arcana4, a completed mirror hook and a trusted mentor (or discovered archive). Receipt Q5 records the satisfied branch and underlying sequences. At level7 the mentor dies and a mutation is cured. Level5 remains legal; generic earned training persists. A graft-powered ability can become unavailable **only** if its definition separately declares current-use dependence. A later continuation requirement is evaluated anew. Another character cannot borrow Q5: character ID, prior build and choice hash differ. A temporary grant must explicitly be an allowed entry source; ordinary short-lived combat buffs are excluded by default. Respec requires a new reviewed history, never reuse of a receipt at a different step.

## 9. Investigation and encounter handoff

Campaign owns `PreparationRecord {id, encounter_ref, discovery_receipt, contributor_ids, world_refs, kind, payload_ref, audience, expiry, consumption, revision}`. Separate an informational claim (observer knows/suspects a fact) from an authoritative encounter change (reinforcement removed by an actual sabotage event).

| Contribution | Concrete output | Consumer |
| --- | --- | --- |
| Wayfinder tracks routes | Optional validated deployment-zone ref | Encounter compiler; does not teleport units during initiative |
| Mason background examines supports | Revealed breakable-object interaction | GAME-33 map object with ordinary action/counterplay |
| Adept reads residue | Evidence that a perceived source may be false | Observer belief; no secret `is_illusion` pointer in UI/AI |
| Healer identifies poison | Known damage type plus access to a costed preparation | Knowledge + GAME-32 resource/status definition |
| Scout disrupts signal | Changed reinforcement schedule from a committed site delta | EncounterSpec; no unexplained universal defence debuff |
| Negotiator finds testimony | New dialogue/avoidance option | Campaign outcome owner |

Battle start pins preparations and participant snapshot hashes. Invalid/expired/contradictory advantages reject or produce a declared public unavailable reason before commitment; they are not silently replaced. Consumption occurs once when the encounter is durably created, not every load. Show “who / what found / usable benefit / expiry or cost.” Carry permitted knowledge to the same human/AI observations. GAME-33 returns consequence **facts** (downed actor, rescue, retreat, lethal outcome) in an idempotent result; Character Life interprets them once after the battle through an approved consequence policy.

## 10. Mortal consequences, roster and legacy

No final death model is locked. Compare permadeath, rare death with rescue, explicit mortal choice and a scarce survival charge in the later prototype. Recommend beginning tests with a clear downed/extraction/retreat boundary and recoverable injury; an unrescued lethal result can still matter. Never map every zero HP to random permanent mutilation. Severe outcomes must cost something—lost objective, treatment time, equipment or an openly chosen sacrifice—without offering an invariably superior transformation reward.

For a three-person start, critical content requires a minimum viable recovery/temporary replacement path. No death simulation benefit is worth blocking the entire campaign. Scar presentation can preserve memory after impairment heals. Immediate fear/panic uses short normal statuses, aftermath fatigue/nightmares use bounded recovery, and rare trauma uses a contextual aspect with support options. No compulsory constant turn theft.

Roster status is separate from competence: active, recovering, retired, trainer, mentor, administrator, specialist or temporary hire. Retired heroes can teach a documented capability, maintain a facility, sponsor a lead or advise a recruit; not all confer bonuses simultaneously. Work ethic/quirks explain assignments or contracts, never random uncontrolled combat commands. Long time advances only at named campaign boundaries; do not import Wildermyth's chapter decades before expedition/downtime pacing is proven.

Adopt within-playthrough legacy first: memorials, taught techniques, obligations and NPC callbacks. World-specific legends belong to explicit playthrough/world-history exports, not mutation of the immutable world template. Cross-campaign reuse may later import a **new identity with provenance and no automatic power**, but is deferred. No cross-save hero resurrection, duplicated inventory or mandatory generational breeding system.

## 11. Save/reload, knowledge and acceptance

Campaign transaction stages all life, mechanics, inventory, relationship and world-delta changes together using the existing lock/journal model. Stage/commit/acknowledge receipt IDs make retries return the original result. Missing life section loads as absent; migration previews deterministic initial hooks and preserves all old fields exactly. Missing packs/pins refuse the affected operation without silently dropping a curse or resetting resources. Archive canonical integer JSON, explicit RNG algorithm/state and ordered IDs. Calendar time, hash-map order and rendering never select an outcome.

Authority owns all truth. Each observer projection discloses permitted aspect descriptions, symptoms, relationship beliefs and evidence. A hidden curse may be a known symptom with an unknown cause. Legal option lists, error messages, logs and previews must not become free truth oracles. Authority hashes/receipts are not public payloads. Player-facing uncertainty is labelled; actual dangerous irreversible commitments disclose the known consequence range without revealing hidden rolls.

Required future acceptance: migration preserving exact IDs/old bytes; two-source grant removal; suppress/resume without refills; historical prestige remains valid after mentor death/cure; current-use dependencies stop appropriately; body conflict preserves inventory; duplicate event/battle-result retries have no effect; save/reload at offer and consequence boundaries matches hashes; two observers cannot infer hidden cause from otherwise identical public data. These are implementation gates, not tests executed by this documentation PR.
