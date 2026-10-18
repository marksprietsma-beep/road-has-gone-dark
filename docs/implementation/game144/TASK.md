# CODEX — GAME-144: Repair v19 Post-Merge Regressions

Repository: https://github.com/marksprietsma-beep/road-has-gone-dark

**Primary task:** GAME-144  
**Parent milestone:** GAME-123 — Rich, Game-Ready Character System  
**GitHub issue:** https://github.com/marksprietsma-beep/road-has-gone-dark/issues/136

## 1. Critically evaluate the task

Before making changes, review these instructions against the current repository and refine your execution plan for efficiency.

This is a focused regression-repair task, **not another character-content expansion**.

Prioritise identifying the actual root causes, repairing them correctly and restoring green Windows validation.

## 2. Establish the current baseline

Fetch latest `origin/main`.

Last verified commit:

`c2a2fdecf12480d3e383d04da1ffe988c9fcd632`

This includes PR #135 / GAME-129, introducing immutable v19 character rules and actual Soulknife, Warblade, Crusader and Swordsage mechanics.

Check whether any subsequent work has been published. If an existing GAME-144 branch or PR is already underway, inspect and continue it rather than duplicating work.

Otherwise, create a new branch from latest main.

Read GAME-144, GAME-123, the existing implementation, and the relevant test suites.

## 3. Investigate five failed Windows workflows

### A. GAME-112 Waves Two and Four

Failed workflows:

- https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39107568880
- https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39107568971

Both report four failures in `tests/opportunities/corpus.gd`:

- Current combat source matches reviewed adapter list.
- Exactly one approved v10/v11 capability adapter.
- Reviewed additions reconstruct exact GAME-121 combat source.
- Protected V1/combat/source/icon contract unchanged.

Investigate whether these assertions incorrectly assume `scripts/combat/tactical_combat.gd` has never changed.

GAME-129 introduced legitimate v19-specific Scout movement handling.

Preserve historical version behaviour. If the tests rely on outdated source fingerprints, update their version-aware evidence without weakening the original behavioural guarantees.

Do not simply delete assertions or replace them with unconditional success.

### B. GAME-112 Waves Three and Five

Failed workflows:

- https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39107568905
- https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39107568873

The native character tests report:

- New class command persists exact authority — FAILED.
- New class battle completes — FAILED.

Other mechanical, tactical and prestige checks passed.

Reproduce the failing commands and inspect actual campaign state, resource handling, combat turns and save/reload results.

Determine whether the issue is a changed command sequence, stale fixture, v19 rules interaction or genuine gameplay regression.

Repair the underlying cause without bypassing real validation.

### C. GAME-133 Sorcerer/Druid Regression

Failed workflow:

https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39107569034

The Godot capture stage reports:

`render fixture retains valid owner/companion identity`

Affected actor:

`51f11c116f417755b21f95ea0bdf05ff:adventurer:2`

Earlier mechanics, compatibility, earned progression and saved combat stages succeeded.

Inspect the real owner/companion identity lifecycle, including actor creation, saved IDs, creature ownership and rendering fixtures.

Do not manufacture replacement IDs merely to make screenshots pass.

## 4. Implement the minimum correct repairs

Classify every failure as:

- Genuine production defect.
- Invalid or outdated test expectation.
- Historical version/fixture mismatch.
- Test infrastructure issue.

Provide specific evidence for each classification.

Fix the smallest coherent set of production or test files needed.

Preserve:

- Immutable rules packs v1–v18.
- Correct v19 character mechanics.
- Existing saves and campaign rules pins.
- Deterministic combat and RNG.
- One RulesCharacter/RulesEffects/TacticalCombat authority.
- Existing XP and Playthrough save systems.

No additional classes, spells, feats, enemies, settlements or world features.

## 5. Windows validation

**Windows only. Do not run Linux validation.**

During development, run focused reproductions of the failing phases rather than continuously repeating the entire expensive test suite.

After repair, execute the complete required Windows validation.

Acceptance requires:

1. All five previously failing workflow classes now pass.
2. GAME-129 dedicated native verification still passes.
3. GAME-130, GAME-126 and relevant existing Windows checks remain green.
4. Exact historic rules pins and old campaigns remain compatible.
5. Genuine v19 character abilities remain functional.
6. Save, cold restart, combat completion and companion identity are correct.
7. No test was disabled, weakened or bypassed to conceal a regression.

If additional failures emerge, distinguish new regressions from unrelated infrastructure issues, and repair genuine blockers.

## 6. GitHub and Linear

Commit and push the completed repairs.

Create a PR against the latest main, inspect the actual diff and verify the required Windows checks.

Merge the PR when all required checks pass. Verify the resulting main commit and post-merge validation.

Do not leave fully validated work unmerged.

Update:

- GAME-144 — repair details, evidence and completion.
- GAME-123 — latest character milestone state.
- GitHub issue #136 — resolution and PR link.

If direct Linear access is unavailable, update GitHub and report the limitation accurately.

Do not close GAME-123: the wider supported-class readiness milestone is still incomplete.

## 7. Prepare the next character-completion wave

Once validation is green, review:

`docs/implementation/game129/READINESS.md`

The 32 base classes and 18 prestige paths are currently recorded as PARTIAL, with specific outstanding functionality and acceptance gaps.

Recommend the highest-value next bounded coding wave based on the remaining weaknesses, prioritising real functionality rather than increasing catalogue counts.

Likely areas include Scout, Swashbuckler, Rogue, Knight, pact/invocation classes, and remaining caster repertoire gaps.

Do not implement that next wave within GAME-144.

Our overarching sequence remains:

**Repair GAME-144 → finish supported class functionality under GAME-123 → move to GAME-142/GAME-141, building the broader living-world prototype.**

## 8. Final report

Provide:

1. Root cause of each regression group.
2. Exact production/test files changed and why.
3. Windows validation results with links.
4. Confirmation that historical rules and saves remain intact.
5. PR, merge commit and final main status.
6. Linear and GitHub issue updates.
7. The exact next character-completion task.

If usage limits interrupt this session, provide a precise recovery checkpoint with the branch, latest pushed commit, unfinished repairs and next action.

**Priority: restore fully trustworthy Windows validation first, then resume completing our existing playable character system.**