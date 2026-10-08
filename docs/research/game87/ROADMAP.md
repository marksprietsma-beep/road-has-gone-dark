# Roadmap and complexity budget

This is a recommendation for reviewed follow-up work, not a set of newly opened tickets or authorization to implement those systems. GAME-32 remains accepted for review; GAME-33/34/35 are not started by this research PR.

## Revise the proposed order

Keep GAME-33 deterministic combat next, followed by GAME-34 manual play and GAME-35 same-engine control. Preserve the life/preparation/action-budget interfaces in GAME-33 now. Do not require every future Haste/graft/pact to work in its first production slice.

Move **one investigation payoff and a small two-stage personal hook** earlier into Character Life V0, rather than delaying the meaning of expeditions until after corruption. Move **minimum treatment/recovery/access and a temporary replacement route** ahead of severe injury. The proposed original order risks implementing penalties before remedies and several affliction systems before demonstrating personal attachment.

Do not make the entire mature GAME-35 policy a prerequisite for writing life fixtures. Once GAME-33/34's encounter boundary and result transaction are stable, life contract tests can proceed; actual auto parity is a release gate before life combat effects ship. No parallel production effort is assumed or started here.

## Ranked value versus cost

Scores1–5 are explicit design estimates (higher value is better; higher cost is worse), not measured productivity. Content/QA cost counts alongside code. Ratios are prioritization hints, not a mathematical proof.

| System | Emotional / gameplay value | Implementation + content cost | Value/cost | Stage / reason |
| --- | ---: | ---: | ---: | --- |
| Contributor-labelled investigation evidence/payoff | 5 | 2 | 2.5 | V0 bridge: directly answers GAME-84 reward confusion |
| Aspects, two hooks and callbacks | 5 | 3 | 1.7 | V0 core: persistent differentiated decisions |
| Typed relationships for story casting | 4 | 2 | 2.0 | V0, no combat bonus economy |
| Event memory and safe offer/commit | 5 | 3 | 1.7 | V0 infrastructure: repetition/reload integrity |
| A two-stage personal search | 5 | 3 | 1.7 | V0 proof, not a universal quest planner |
| Coarse motivation/voice | 3 | 2 | 1.5 | V0 small; no personality simulator |
| Limited downtime + facility access | 4 | 3 | 1.3 | V1 before lasting penalties |
| Scoped reputation and simple occupation | 4 | 3 | 1.3 | V1, sparse scopes/duties rather than job levels |
| Recoverable injury/scar + treatment | 5 | 4 | 1.25 | Consequences slice after recovery route exists |
| Source grant ledger + qualification history | 4 | 4 | 1.0 | Before any life mechanics/entry depends on it; essential correctness |
| One prosthetic/graft | 4 | 4 | 1.0 | After body/equipment preview, retain old build option |
| One curse or exposure/mutation arc | 4 | 4 | 1.0 | Later selected acquired state; no full domain matrix |
| Patron agreement | 3 | 3 | 1.0 | Later optional social access; no mandatory campaign patron |
| Disease/pact/symbiont breadth | 3 | 5 | 0.6 | Later, each must justify unique decisions |
| Transformation chain | 5 | 5 | 1.0 | Later after grant/body/history correctness and art budget |
| Guild retirees/mentors | 4 | 4 | 1.0 | Later after roster actually expands |
| Cross-campaign powered legacy | 2 | 5 | 0.4 | Defer indefinitely pending world/save identity policy |
| Detailed organs, daily relationship upkeep, universal alignment meter | 1 | 5 | 0.2 | Reject: bookkeeping or identity contradiction |

## Delivery stages and exit gates

| Stage | Concrete scope | Dependencies / exit gate |
| --- | --- | --- |
| 0: current review | Keep GAME-32 PR69 and research PR68 unchanged; review this GAME-87 synthesis | Accept ownership/version/action exceptions; no merges performed here |
| 1: GAME-33 | Baseline rules adapter, sequence-ready resolution, explicit clocks/budgets, knowledge boundaries, encounter preparation envelope and atomic result | Same commands replay identically; no renderer/AI rules; a synthetic finite sequence fixture proves extensibility |
| 2: GAME-34/35 | Manual choice/cost/uncertainty UI; same legal-command auto policy and replay | Controller switches preserve budget/pending effects/observations; real protected-ranged/objective/control tests |
| 3: Character Life V0 | Versioned aspects, directed relationships, motivation, two hooks, selector/memory/receipt,16 core templates from24-template proof corpus, expedition callbacks, one personal arc and investigation bridge | Old characters/IDs intact; save/reload/duplicate commits safe; uniqueness A/B and contributor clarity evaluated |
| 4: Character Life V1 | Two-opportunity downtime, sparse standing, simple occupation, training/contact facilities, richer investigation preparations | No repeated chores; duties/access have visible costs, clock advances once; optional sponsor evidence |
| 5: lasting consequences | Recoverable wounds/scars, limited aftermath trauma, treatment, substitute access, mortal-choice comparison; one body/graft prototype | Consequence retains viable play; source ledger/body rules if mechanical; no automatic permanent mutilation at0HP |
| 6: acquired states | Shared typed lifecycle implemented incrementally: first one curse OR one exposure/mutation arc; then selected disease/pact content | Generic reconciliation, visible risk/remedy, hidden-truth projection; no resource/cure farming or forced builds |
| 7: earned advanced paths | Qualification receipts, life-gated prestige and a broader personal quest sequence; coordinate later GAME-36 content validation | Historical entry survives source removal; current-use requirements explicit; unavailable worlds have alternative access |
| 8: transformations and roster life | One staged transformation; later symbiont/retirement/mentor/trainer/administrator/specialist roles | Body/grant/replay/art costs known; former heroes useful without passive bonus stacking |
| 9: legacy | Within-playthrough memorials and world-specific history export | Preserve template/playthrough provenance. Powered cross-campaign reuse remains deferred |

If a stage wants life-based prestige sooner, move the **receipt prerequisite** before that feature; do not add raw live tags and promise to repair old history later. Likewise mechanically meaningful aspects require the source ledger before first shipping grant content; V0's nonmechanical facts can proceed without it. Eight advanced corpus templates remain capability-gated, not omitted research.

## What should change now: complete decision classes

| Classification | Findings |
| --- | --- |
| **NO ACTION NOW** | GAME-32 acceptance, existing class tuning, GAME-86 experiment counts/results, current production identity schema; retain pins and pending PRs |
| **GAME-33 REQUIREMENT** | Single budget/payment authority; finite attack sequences; explicit normal/extra/global boundaries; future grant sources/caps and loop rejection; observation-safe commands/previews; preparation inputs and idempotent aftermath facts |
| **FUTURE CHARACTER-LIFE REQUIREMENT** | Life-owned typed records and grants; transactional offers/results; sparse relationships/standing; hooks/callbacks; source-aware removal; recovery/access before lasting penalties; stable world/character IDs |
| **FUTURE GAME-32 SCHEMA EXTENSION** | Source grant ledger/projection and pool retention; qualification receipts + entry/continuation/use; body/item capability allocation; normalized extended costs/sequences; snapshot composition pins; replacement choices |
| **FUTURE CONTENT** |24 proof templates, original prestige/heritage options, a costed Haste experiment, restrained protection/rescue options, one curse/mutation/graft/pact path at a time; all tested against same engine |
| **REJECT / DO NOT BUILD** | One universal reputation/morality/sanity bar; class=occupation or culture=ancestry; feat-for-flaw farming; free romance DPS; random forced class levels; per-step disease/body simulation; compulsory patron; arbitrary event scripts; separate autoresolve formulas; recursive extra turns; unconstrained prose authority |

## Budget enforcement

No feature enters because another RPG contains it. Each proposed addition must identify a new decision, a persistent owner, a remedy/removal policy, an observation boundary, a test fixture and its production/content cost. If two categories make the same choice, ship one. Do not open a ticket for every row before the previous slice demonstrates value.

The first event corpus is deliberately small:16 immediately useful stories and8 future boundary probes. Additional variants should repair demonstrated repetition or missing-world coverage, not inflate a target count. Source material can inspire a thousand possibilities; the delivered game only needs a few that remember what the player did.
