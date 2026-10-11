# Progress and the next useful ticket after GAME-99

The game now has a connected technical spine: offline generated worlds and library selection; source-backed origin/hometown choice; three persistent adventurers and LPC presentation; local geography, scouting and travel; generated tactical encounters; saved battle progress; recorded outcomes and return home. GAME-99 removes a serious barrier to reaching that loop while preserving existing campaigns.

The next gap is **a reason to care about an opportunity and the people undertaking it**. More generated encounters alone will not establish that. Journey XP is still a placeholder; V0 rest and consequences are deliberately limited. Wider class/control/illusion and character-life designs should remain contracts until a smaller playable need justifies implementing them.

## Recommended ticket: Local opportunities with choices and remembered outcomes V1

Deliver one 10–15 minute human playtest using existing world facts, party identities, opportunities, combat and save ownership:

- An **investigation** with concrete evidence and a named companion contribution, ending in a finding that is visible after returning home.
- A **confrontation** with a clear purpose, stakes and one bounded noncombat choice where the local context supports it. Reuse the existing battle for its combat option; remember the distinct outcome.
- A **personal lead** attached to one existing companion hook, with one small follow-up after return/reload. Preserve the companion's identity rather than generating a replacement.

Keep the implementation to three authored, context-qualified templates and one two-stage personal callback. Each should explain why it is here, why this party cares, what the player can change and what was remembered. Source-backed geography must remain true; generated local fiction should be identified as such. Do not invent the same harbour or relative in every hometown.

Acceptance: two worlds and at least six hometown contexts; one meaningful noncombat decision and one existing battle; no repeated reward on replay/double activation; deterministic persistence and old-campaign compatibility; a reviewer can explain what changed and which companion mattered after returning home.

Exclude a full GAME-87 event framework, inventory/equipment, ancestry or injury mechanics, new combat authority, town generation, guilds, dungeons, a new save writer and another art comparison. Do not assume prototype Emberkin or the current eight peoples are the final ancestry roster. Keep ancestry/heritage/culture, character build and acquired life history distinct, as GAME-88 establishes.

## Open research awaiting review

These are open **GitHub research/review PRs**, not a claim about unavailable Linear statuses. They represent retained work to review or extract when needed, not six sequential development milestones:

| Work | Useful next application |
| --- | --- |
| [#51 — GAME-67 facility evaluation](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/51) | Later, a minimal hometown contact/facility. Respect unresolved geographic scale and source/licensing boundaries before adopting Settlemaker integration. |
| [#52 — GAME-69 settlement-art comparison](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/52) | Retain presentation evidence until a town interaction requires it. |
| [#53 — GAME-70 native inspection proof](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/53) | Reuse navigation and world/region/town review criteria. |
| [#54 — GAME-71/72 labels and facility markers](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/54) | Improve discoverability if playtests show a concrete navigation problem. |
| [#55 — GAME-73 geographic coherence](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/55) | Keep ownership, shoreline and neighbor consistency as constraints. Do not revive the rejected town-rotation experiment without new evidence. |
| [#61 — GAME-78 generator/context evaluation](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/61) | Extract a small reviewed set of context facts/content for the three opportunities; retain the current generator. |

GAME-86/87 research and the accepted GAME-88 character-direction guide already provide deeper future direction. There is no need to redo their synthesis. After this small content slice, choose the next change from playtest evidence: improve tactical objectives if battles lack decisions, or add one useful hometown contact/downtime interaction before permanent injuries and larger life systems. GAME-98 icons can wait unless players cannot find their next action.

No new ticket was opened or implemented as part of GAME-99; this is a recommendation for review.
