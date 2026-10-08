# Event engine contract — deterministic casting and committed consequences

Proposed Character Life service, not a production implementation. [Character Life](CHARACTER-LIFE-CONTRACT.md) owns facts and grants; this service proposes opportunities and coordinates validated outcomes through the campaign transaction owner. It never owns an alternative combat engine.

## Definition, trigger and inputs

```text
EventDefinition:
  id, version, content_hash, provenance, family_id
  trigger, required_capabilities[], roles[], eligibility_ast
  weight_policy, memory_policy, choice_definitions[], prose_templates
  outcomes_by_choice, visibility_policy

EventContext:
  playthrough_id, world_pin, campaign_revision, campaign_tick
  expedition_id?, encounter_id?, trigger_receipt, present_character_ids[]
  life_revision, rules_ref, life_pack_ref, event_pack_ref
  permitted_world_entities, authority_knowledge, event_memory_revision
```

Initial trigger registry: `expedition_departure`, `site_investigated`, `expedition_return`, `town_service_completed`, `downtime_completed`, `hook_evidence_added`, `battle_result_committed`. The last three are capability-gated until their owners exist. No frame-by-frame background polling, arbitrary timer scripts or direct production integration in this PR. One trigger receipt can offer at most one focal event; a chained consequence becomes a queued later boundary, not recursively another immediate story.

Definitions are immutable and version-pinned. Reject duplicate IDs, missing references, undeclared outcome types, cyclic prerequisite dependencies, unbounded role domains, overlapping exclusive outcomes and impossible body/grant references before enabling a pack. A missing future capability disables that template with a diagnostic; it must not simulate a curse or combat advantage using prose alone.

## Eligibility AST and typing

Use a closed AST distinct from GAME-32's mechanical requirement namespace. Share comparison/boolean conventions where useful; do not teach the rules kernel what a town is.

```json
{
  "op": "all",
  "args": [
    {"op":"background_tag","role":"lead","tag":"mining"},
    {"op":"hook","role":"lead","kind":"missing_mentor","state":"pursued"},
    {"op":"relationship","from":"lead","to":"helper","type":"friend","at_least":1},
    {"op":"site_type","role":"site","type":"abandoned_mine"},
    {"op":"world_state","entity_role":"site","fact":"accessible","equals":true}
  ]
}
```

Supported families and typed adapters:

| Predicate | Query / owner |
| --- | --- |
| `all`, `any`, `not` | Boolean structure, max depth16, max16 children; no eval strings |
| `has_aspect`, `lacks_aspect`, `acquired_state`, `injury`, `corruption_stage` | Definition/status/stage on Character Life; does not inspect prose |
| `relationship` | Directed from/to IDs, declared type, coarse strength |
| `background_tag`, `people`, `heritage`, `origin`, `religion` | Valid identity/world references; culture separately queryable |
| `class`, `feature`, `feat`, `skill` | Pinned derived rules context, identified as current or historical; never parse a class display name |
| `region`, `site_type`, `facility_type`, `faction` | Resolved world+campaign entity adapter |
| `hook`, `ambition`, `occupation`, `duty`, `reputation` | Structured life/campaign records with explicit subject/audience |
| `time`, `previous_event`, `world_state`, `known_evidence` | Integer campaign boundaries, event memory, typed world facts and named observer knowledge |

All predicates return `true`, `false` or `unknown` with `{code,path,subject,current,expected,evidence_refs}` in authority diagnostics. Missing data is not proof of absence: `not(unknown)` is unknown, and only true grants eligibility. `lacks_aspect` requires a complete authoritative aspect set. Public explanations redact hidden facts. Schema errors are errors, not unknown. Unknown fields/operators reject. No arbitrary SQL, regular expressions over biography, unrestricted recursion, user-defined functions or executable asset paths.

## Casting characters, relationships and places

Roles declare entity kind, finite domain (`present_party`, bounded roster, known site candidates, eligible local facility), required/optional, equality/exclusion constraints and scoring. Resolve indexed candidates in stable ID order; filter the most constrained lead first, then dependent roles. Enumerate feasible complete bindings and verify the whole AST, so a greedy first lead cannot hide a valid later cast. No relationship helper may silently become the lead. Optional absent roles use a specific prose/outcome variant with no dereference of null.

For the initial content contract, max4 roles, max12 candidates per role, and a validator-proven bound of4096 explored bindings per template; narrower domains are required when the product exceeds it. If the bound cannot cover the declared domain, reject the template rather than silently truncate and bias selection. Cache indexes by world/life/knowledge revision; never cache a live relationship or “eligible quest” across its dependencies changing. Large future rosters need a reviewed scheduler, not broader brute force.

Sites/facilities must be real referenced entities and appropriate to the trigger's location/reachability. Existing campaign truth constrains a hook's locations; an event cannot retcon them for convenience. Selectors can use authority facts to schedule an unrevealed story, but the resulting offer must satisfy its disclosure policy. No option label “cure your hidden curse” before the player has symptom/evidence access.

## Integer weighting and repetition

Select **template first, binding second** so a large roster does not multiply one story's chance merely by producing more casts. For each eligible template, compute this proposed integer weight:

```text
weight = floor(base_weight * novelty * hook_priority * spotlight / repeat_divisor)
base_weight: authored 1..100
novelty: 4 if never offered this campaign, otherwise 1
hook_priority: 2 if it advances a chosen pursued hook, otherwise 1
spotlight: 2 if any feasible lead has no focal event in the last 3 expeditions, else 1
repeat_divisor: (1 + campaign_times_offered)^2
```

Clamp positive weights to1..1600 **after** hard exclusions; a zero from a cooldown remains excluded. If all templates are excluded, offer no focal event rather than breaking cooldown. Prototype defaults: unique hook/major-state events once per character/arc; ordinary template cooldown3 completed expeditions; family cooldown1 expedition; same lead+family cooldown3; no more than one focal personal event per expedition. Routine revisit events grant information or bounded situational options, not permanent stat rewards.

Among selected template's bindings, prefer eligible leads with least recent spotlight, then the template's declared bounded fit score; equal scores use a separate seeded draw over canonical binding IDs. This preference cannot make an ineligible lead eligible. Character strength or class is not a blanket priority multiplier.

A saved named RNG stream, e.g. `event_selection_v1`, uses a pinned SHA-counter/rejection-sampling algorithm and length-delimited canonical input: playthrough seed, trigger receipt, offer ordinal and content pin. Template and binding draws have separate counters. Never use wall clock, language hash(), dictionary order or animation RNG. Whole candidate ordering/weights and draw counters are authority audit data; public offers expose only permitted results.

```text
EventMemory:
  template_id, definition_ref, family_id, times_offered, times_resolved
  last_offered_tick/expedition, last_resolved_tick/expedition
  character_binding_ids, variant_id, resolution_id, cooldown_until
  unique_arc_receipts[], last_offer_id
```

Record offered and resolved separately. Declining consumes the opportunity and cooldown so reopening a menu cannot fish for a better cast. Saving/reloading never resets offers. Family suppression applies to renamed variants. Optional account/profile novelty is deferred: it would otherwise make two identical playthrough seeds differ due to external player history unless that history were explicitly imported and pinned.

## Outcomes and previews

Closed outcome registry, each with validation and owner:

| Operation family | Owner and constraints |
| --- | --- |
| Add/suppress/remove aspect; change motivation/ambition | Life instance transition, pinned definition, no overwriting identity |
| Change relationship; advance/resolve hook | Existing edge/hook IDs and evidence; bounded growth; no duplicate reward |
| Change standing; create/fulfil duty or pact | Explicit subject/audience/counterparty; no universal reputation propagation |
| Grant item/training eligibility/feature | Inventory or source-grant transaction; training is permission, not an automatic class level |
| Apply wound/start recovery; exposure/curse/mutation/graft/transformation | Typed acquired-state transition, capability gate, body/equipment/grant preview |
| Unlock quest; change facility/site/world delta | Existing campaign owner validates references and preserves immutable template |
| Reveal evidence; grant encounter preparation | Knowledge/PreparationRecord with contributor, audience, scope and expiry |

Every operation identifies `operation_id, expected_revision, source_offer/receipt, visibility, typed_payload`. Definitions cannot call tools or scripts. A trusted new operator is a versioned engine extension with validation and replay tests. A finite declared outcome list is not permission to mutate any campaign property.

Preview returns costs, known certain consequences, unknown risk range and affected inventory/abilities/standing/hook links. It displays what was learned and who contributes. It does not sample future outcome RNG, reveal a hidden branch's truth, or promise exact damage through an undiscovered resistance. No arbitrary repeated probability checks for routine competent background knowledge: use a deterministic option when expertise suffices. Actual uncertain checks use GAME-32's numeric primitives through the approved campaign adapter, not a new event dice system.

## Offer, choose, commit: crash-safe protocol

1. Under the campaign guard, validate the trigger receipt and expected revisions. Build candidates and select with explicit RNG. Persist **one PendingOffer** containing offer ID, definition pin, actor/site bindings, permitted choices, authority input hashes and post-selection RNG counters. Also persist offered-memory updates. A repeated trigger returns that offer.
2. Render the persisted projection; reopening never recasts or rerolls. Pause relevant campaign mutations while a modal choice is pending. If an external authoritative change invalidates a binding, mark the offer expired once, explain the known reason and enqueue a future trigger; never silently swap a hero/site under the selected answer.
3. On choice, validate ownership, choice ID and all expected revisions under the same guard. Derive outcome from the pinned definition and reserved outcome stream/nonce. Choice IDs scope different prescribed branches; the selection stream remains independent. A rejected command consumes nothing.
4. Stage the full candidate, receipt, post-outcome RNG and all associated world/life/mechanics/inventory changes through the existing journal. Validate the complete candidate including body/resource invariants. Commit atomically. Retry by `offer_id+choice_commit_id` returns the committed receipt; a different second choice receives `event.already_resolved` without new RNG.
5. Only after commit render outcome prose and enqueue finite follow-up opportunities. Crash after staging recovers the staged candidate; crash before staging recomputes the identical outcome. No reward is committed independently of its cost or memory.

The campaign transaction is responsible for locking/recovery integration; this is not a second independent event database. Honest save/reload resumes the same outcome. An offline single-player save format cannot prevent a person from deliberately restoring an older file and making a different decision; this contract does not claim anti-cheat security or require forced ironman.

## Prose, voice and knowledge

Author a short situation, two or three consequential options, an outcome skeleton and a callback. Generated facts fill entity references; deterministic variation selects among authored variants. Prose is a **derived view**, never a parser input. Optional generated prose later cannot invent relationships, locations, promises or mechanical rewards; if it fails validation, use the authored fallback.

Use a few contextual voice tendencies to vary wording and voluntary reactions. A grieving hero need not sound permanently sad; a rival can still cooperate. No ancestry caricatures or personality-driven forced choices. Store the selected variant ID so save/reload keeps the presentation stable.

Observers receive symptom/evidence projections, not authority IDs, receipt payloads, RNG states or all rejected eligibility reasons. Test both explicit leaks and indirect leaks via options, sort order, error text and unavailable-action highlights. A hidden fact may legitimately be revealed by a paid/committed investigation, but the evidence event must say what changed in that observer's knowledge.

## Required future verification

- Permute map/dictionary/candidate order: identical offer, bindings, RNG counters and hashes.
- Same template with1 versus10 valid casts: no unintended tenfold template probability.
- No candidates, exhausted cooldowns, missing required helper, conflicting site truth and missing future capability: no invented facts or fallback rewards.
- Malformed AST, over-bound role domains, unknown outcome, conflicting body grants and cycles: structured rejection before play.
- Inject crashes before/after offer staging, choice staging, commit and acknowledgement; rewards/costs/world deltas occur once and committed RNG never rerolls.
- Delete rendering/change language: eligibility/outcomes stay identical. Save/reload preserves variant and choices.
- Identical permitted observations with different hidden curse/illusion truth: previews/error strings do not leak; a declared reveal event can legitimately diverge afterward.
- Repeated trivial trips cannot farm relationships, stats, grants, income or survival charges.
- Exercise the24 templates in [PROTOTYPE-PLAN](PROTOTYPE-PLAN.md), including all branches and negative bindings; do not assert emotional success from schema checks alone.
