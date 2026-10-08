# GAME-32 acceptance audit

Audit resumes the existing branch and kernel; no new architecture assessment or branch. Requirements authority is Mark’s original GAME-32 brief plus the subsequent continuation request. The GAME-87 synthesis is design context only. Linear is managed separately by ChatGPT; no issue updates were attempted here.

| Requirement | Implementation and executed proof |
| --- | --- |
| Existing immutable character IDs, identity/history | `RulesRecords` keys builds by existing IDs; migration removes only the new mechanics object and compares the complete source campaign, party and characters exactly |
| Historical GAME-81/84 saves | Missing mechanics remains valid/not_prepared; real party generation, ready handoff and active expedition accept/depart precede deliberate preparation |
| Atomic preparation and advancement | Existing slot/world guard, journal, reload verification and rollback; stale/tampered/duplicate previews leave save bytes equal |
| Distinct narrative roles/classes | Existing party/member schema is unchanged; role recommendations choose original mechanical paths in a separate record |
| Exact rules pin | Package/schema/rules/engine/content hash enforced at build and campaign validation; round-trip integer normalization; mismatched pin rejected |
| Stored versus derived | Ordered choices/current HP/resources/statuses persist; stats/capacities/abilities reconstruct into an immutable authority snapshot |
| Attributes, skills, equipment and feats | Deterministic standard array; trained skill/rank budgets/modifiers; equipment refs/slots/requirements; scheduled feats and attribute increases |
| Safe formula and prerequisite AST | Bounded depth/arity/integer calculations; ALL/ANY/NOT plus level/class/attribute/skill/feat/feature/tag/BAB/save/casting/resource/ancestry; structured reasons |
| Typed modifier behavior | Greatest typed positive plus worst typed negative; untyped stacks; stable source/content tie ordering; malformed conditions/types reject |
| Level20 engine and ordered multiclassing | Three pure paths, martial/skirmisher, adept/skirmisher and base/prestige/base paths through every level; level cap and exact historical order checked |
| Explain options and invalid advancement | Class/partial-choice option preview; exact point spending, rank/feat/attribute schedule checks; 400 invalid kernel choices and 200 campaign previews preserve sources |
| Distinct three base paths | Roadwarden guard/armour/threat; Wayfinder stride/skills/contextual precision; Lantern Focus/control/perception/healing/delayed magic |
| Nontrivial prestige | Veil entry tests every prerequisite failure type; ten prestige levels retain base features; shared-reaction trusted Echo and illusion descriptor proof |
| GAME-86 economy | Move/main/shared reaction only; Dash/Charge/Disengage descriptors; departure and Echo share one reaction; activation cannot refresh it |
| Resources and persistence | Encounter/eligible-rest/daily definitions plus short-rest/explicit fixture scopes; current Focus survives save and process restart without refill |
| Statuses and effects | Duration/expiry/stacking and typed modifiers; explicit-boundary expiry; safe child-effect execution; expansion cycles reject; damage/heal/temporary HP/save tests |
| Original safe hooks | Fixed versioned handler ID registry, declared inputs/events/intents; no arbitrary content script/eval/path execution |
| Illusion/per-observer contract | Nonphysical descriptors with senses/investigation/disbelief/DC/bypass/maintenance; public projection excludes authority truth; battlefield owner selects observer beliefs |
| Delayed/interruption contract | Paid next-activation intent, tile lock/cancellation/friendly-fire/range tags; no immediate damage or scheduling side effect |
| Immutable complete snapshot | Stats/skills/features/tags/senses/legal/prepared abilities/casting/capacities/current state/status durations/maintained descriptors/equipment/actions/build hash/snapshot hash |
| Deterministic RNG and outputs | Explicit SHA-256 counter state; 10,000 equivalent d20 draws; structured/text dice equivalence; committed exact golden stats, hashes and validation codes |
| Negative content | Committed patch fixtures reject duplicate IDs, missing refs, operators/hooks/triggers/formulas/dice/progression/resource policy/extra executable-looking fields and feature/status cycles |
| Stress and profile | 5,000 prerequisites, 2,000 advancement previews, 1,000 round trips, 1,000 derivations/validations/effects, hundreds of invalid attempts, all-level paths and 10,000 RNG comparisons; per-stage timings retained |
| Windows/Linux first checkpoint | Workflow37716987428 fully green on both; downloaded QA artifacts equal on all golden fields and exact pins; `CI-FIRST-CHECKPOINT.json` explicitly scopes evidence to `0aee973` |
| Native first checkpoint | Both complete distributions passed75 checks with bundled compatible helper, empty PATH, hometown/expedition UI and mechanical preparation; ordinary release launch also passed |
| Latest audit source verification | Fresh local suite passed22,172 kernel +233 migration +6 restart checks after the audit changes; final exact-head CI/check/package links belong in the draft PR, not inferred from the first checkpoint |
| Extension sources beyond classes | Generic runtime feature grant gives an adept Light Step/tags/stride; current equipment validation explains an external-feature tag conflict; no character-life feature implemented |
| Scope boundaries | No tactical grid/pathfinding/LOS/initiative queue/AI/autoresolve/combat renderer/character-builder UI/GAME-87 aspects or injury systems; no merge |

## Final self-review

New base/prestige paths primarily add definitions, formulas, feature tiers and prerequisite ASTs. New operators or hooks require a registered, tested engine change rather than executable content. Arbitrary legal level order is supported up to the total/class caps. Ancestry/background/runtime grants provide non-class feature sources; status/modifier effects also carry source IDs. The same original ability definitions are available to human and AI consumers; no controller-specific rule calculator exists.

GAME-33 can consume the immutable authority snapshot and pinned registry without knowing class progression. It must enforce tactical targets/geometry, event eligibility, contextual precision limits, reaction scheduling, maintained-effect expiry/breaks and observer-facing projection. No hidden snapshot should be given wholesale to an observer; real and illusory perceived targets need the same public apparent-reference vocabulary.

Temporary future aspects must not retroactively change the facts under which a historical class/feat was entered. If such grants qualify characters for advancement, GAME-87 must persist their versioned acquisition/qualification history. The current extension interfaces allow effects and current tag queries without inventing that future narrative schema.
