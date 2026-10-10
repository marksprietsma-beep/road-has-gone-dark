# GAME-32 impact — read-only audit of the finished V1 kernel

**No architectural blocker found. No changes requested to PR #69 in this research task.** Character IDs, ordered progression, pinned definitions, safe rules operators and the existing transaction boundary can support the proposed direction. Rich life sources and action budgets need deliberate later schema/API extensions; they are not secretly supported by today's fixed V1 records.

Audit pin: `5caa55f0ea515d57b75c00b8ccbfac17e41948af`. Rules content hash: `104a677976f5e6a91210fa5dd6abfcc0ad578315c8a696a734451694a915d098`. Reviewed docs: RULES-CORE, ACCEPTANCE-AUDIT, VALIDATION and GAME-33-HANDOFF. Inspected implementation: rules_character, rules_registry, rules_effects, rules_expressions, rules_records, rules_service and original data/rules/trhgd-rules-v1.json. Source links below pin the reviewed revision because this research branch does not contain the later production implementation.

## Compatibility classification

| Life need | Classification | Actual evidence / required boundary |
| --- | --- | --- |
| Stable IDs through life changes | **NO CHANGE** | `RulesRecords.preview_preparation` keys additive mechanics by existing party IDs; mutation never creates a replacement identity |
| Narrative roles distinct from builds | **NO CHANGE** | Role recommendations select first build choices, while original role/biography persists separately |
| Classes/multiclass/prestige/skills/feats | **NO CHANGE** | `RulesCharacter._replay` reconstructs ordered steps and checks class/feat requirements. Life events grant opportunities, not unchosen levels |
| Nonmechanical hooks, motivations, careers, relationships and scoped standing | **NO CHANGE** | Future campaign/life records and event eligibility own these. Do not add social tables to the class kernel |
| A current external feature granting tags/abilities/senses | **USE EXISTING EXTENSION POINT** | `grant_feature`, `_context(..., true)` and feature definitions expand capabilities without class-name branches; fixture already proves Light Step on an adept |
| Current mechanical predicate queries | **USE EXISTING EXTENSION POINT** | `RulesExpressions.REQUIREMENT_OPS` covers boolean composition, class/level/attribute/skill/feat/feature/tag/BAB/save/casting/resource/ancestry. No `has_aspect` or faction resolver currently exists |
| Typed modifiers/statuses and simple injury effects | **USE EXISTING EXTENSION POINT** | `RulesModifiers`, modifier/status effect operators, explicit source and expiry. Life owns acquisition/recovery and chooses pinned effects; a permanent wound is not represented by decrementing a battle duration forever |
| Source-specific removal/suppression and two grants of one feature | **FUTURE RULES-SCHEMA EXTENSION** | Runtime grants are unique strings; `_context` labels them `granted:<feature>`. It cannot distinguish two aspect instances or revoke only one. Introduce source grant projection/ledger support |
| Multiple providers/current resource preservation | **FUTURE RULES-SCHEMA EXTENSION** | Existing capacity/current-value separation and scoped refresh are reusable. Source-aware suppression, restoration and pool tombstones must prevent refill exploits |
| Immutable snapshots | **USE EXISTING EXTENSION POINT** | `derive_character` includes rules/build/snapshot hashes, derived stats, tags, skills, abilities, casting, equipment, current resources/statuses, senses and action contract |
| Snapshot provenance for life/investigation | **FUTURE RULES-SCHEMA EXTENSION** | V1 does not carry life revision/grant-ledger pin. Proposed snapshot envelope pins them, while observer projections omit hidden source truth |
| Exact rules/version/content pins | **USE EXISTING EXTENSION POINT** | Registry pin and canonical hashing already reject mismatches. Life/event packs need parallel pins and migration policy, not silent V1 field injection |
| Current equipment conflicts from tags | **USE EXISTING EXTENSION POINT** | `_replay` validates equipment against current runtime-expanded context; fixture proves external-feature conflict explanations |
| Body capacity, equipped item instances and capability occupancy | **FUTURE RULES-SCHEMA EXTENSION** | V1 equipment uses definition IDs with limited duplicate/armour/shield conflicts, not limb-specific item-instance allocations. Extra arms cannot be implemented by appending another sword ID |
| Heritage/trait alternatives and feature replacement | **FUTURE RULES-SCHEMA EXTENSION** | Static ancestry/background roots exist. General feature suppression/replacement, parameterized feat choices and optional class alternatives require a versioned choice/grant policy |
| Life-derived historical prestige qualification | **FUTURE RULES-SCHEMA EXTENSION** | `_replay` deliberately excludes runtime grants at advancement steps; each step has exactly5 fields. Add historical evidence and phase-specific requirements through a reviewed version, not today's live tags |
| Mutable/current mechanics commits | **USE EXISTING EXTENSION POINT** | `preview_runtime` plus `RulesService.commit_preview` rebuild/validate under the existing guard/journal; a future multi-owner life transaction must reuse the transaction pattern rather than chain independent writes |
| Precision as a current-event effect | **USE EXISTING EXTENSION POINT** | Explicit `scope: current_event` emits an intent without persisting damage. Future sequences must keep its first qualifying hit scope bounded |
| Multi-strike, restricted action grants, extra reaction/Main/turn | **FUTURE RULES-SCHEMA EXTENSION** | Costs accept only move/main/reaction0..1 plus resources; budget exactly3 fields; snapshot baseline fixed. New tags cannot alone enable Haste or multiattack execution |
| Life logic reading live world/prose during rules replay | **ARCHITECTURAL RISK** | Would make saves nondeterministic and historical progression retroactive. Prevent through typed historical receipts and pure current projections |
| Revoking a flat runtime string while another source still grants it | **ARCHITECTURAL RISK** | Do not build a life service that “undoes” arbitrary V1 effects by deleting strings. Use a ledger and atomic reconciliation when mechanical life content arrives |
| Dual payment authorities or fake V1 budgets for extra actions | **ARCHITECTURAL RISK** | Do not bypass cost validation by refilling `main=1` around a restricted action; introduce one reviewed shared cost execution API |

## Relevant source anchors

- [Character records, replay, derivation and current grants](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_character.gd): `_shape`, `_replay`, `_feature`, `_context`, `_runtime_errors`, `derive_character`, `preview_advancement`, `available_advancement`.
- [Definition/field validation](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_registry.gd): `validate_effect`, `_validate_definition`, `_validate_rules`; unknown fields and unsupported cost ranges reject.
- [Cost/effect execution](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_effects.gd): `activation_budget`, `refresh_shared_reaction`, `validate_ability_cost`, `use_ability`, `resolve_rules_effect`.
- [Requirement operators](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_expressions.gd), [campaign previews](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_records.gd), [atomic service](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/5caa55f0ea515d57b75c00b8ccbfac17e41948af/scripts/rules/rules_service.gd).

## Extend only when the dependent slice is authorized

1. **Before mechanical life grants:** version source provenance, revocation/suppression, current-pool retention and snapshot composition; test two sources and remove/reacquire without free resources.
2. **Before life-gated advancement:** qualification receipts and explicit entry/continuation/use policies. Preserve V1 replay exactly and migrate with pinned evidence; a mentor's death/cure never retroactively deletes a level.
3. **Before equipment-changing grafts:** item instances, body capability allocation and conflict-preview reconciliation. A slot tag alone is insufficient.
4. **Before extra-action content:** normalized payment and sequence schemas shared with GAME-33, including unsupported-version errors. Baseline encounters still use current V1 content exactly.
5. **Before alternative features/broad prestige packs:** reviewed choice/replacement and pack-compatibility validation, naturally coordinated with future GAME-36.

These are versioned additions to the current separation of identity, choices and derivation. None requires replacing stable IDs, discarding ordered progression or writing a second rules engine. Do not reopen GAME-32 acceptance solely because later Haste/extra-limb content does not fit a purposely small V1 pack.

## Decisions on the D&D option space

| Research family | Structural conclusion |
| --- | --- |
| Base classes and multiclassing | Keep ordered data-defined training; no hundreds-of-classes delivery target |
| Prestige | Requirements plus deliberate investment; life facts may supply audited entry evidence |
| Alternative class features/substitution levels | Named replacement choices with exclusivity and retained history; later schema, not class duplication |
| Racial paragon/bloodline/heritage | Optional heritage talents/milestones; never culture-as-biology or compulsory extra class bookkeeping |
| Inherited/acquired templates | Inherited root versus acquired overlay; preserve origin and class history through transformation |
| Grafts/symbionts | Slot/capability and source/bond identity, not anonymous permanent item bonuses |
| Aberrant/draconic-style feat chains | An acquired seed can open a chosen adaptation path; no forced advancement |
| Traits/flaws | Small consequential aspects; reject choosing a harmless flaw to farm a superior feat |
| Curse/taint/mutation/pact/affliction | Typed acquired-state lifecycle and generic grants; no alignment inference or arbitrary class hooks |

See [Character Life §8](CHARACTER-LIFE-CONTRACT.md#8-qualification-history-entry-continuation-and-current-use) for the proposed historical receipt and [GAME33-IMPACT](GAME33-IMPACT.md) for the action-budget contract. All extensions remain proposals for later reviewed implementation.
