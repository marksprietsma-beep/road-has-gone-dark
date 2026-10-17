# Codex — Resume and finish GAME-126 / PR #117

Before starting, critically evaluate these instructions against the actual repository, PR and test evidence. Correct any mistaken assumption, but preserve the intended scope.

Repository: `marksprietsma-beep/road-has-gone-dark`

Existing branch: `feature/game-126-character-completeness`

Existing PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/117

Linear: GAME-126, under GAME-123.

## 1. Resume existing work — do not restart

The last verified branch head was `83bc79af013a7a1ca6ec4469f49ad8275fc144fd`.

Check the actual current remote state first.

The GAME-126 implementation already includes substantial character-completeness auditing, a new immutable v16 pack, contextual uses of five previously underused skills, and corrected Archmage permanent spell qualifications.

Preserve all completed work, test fixtures, evidence, immutable v1–v15 packs and existing save compatibility.

Do not recreate the audit, introduce new base classes or expand into unrelated gameplay.

## 2. Fix the actual Windows-native failure

The most recent Windows workflow failed:

https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38920339237

Nine checks passed, one failed, and the review-package job was skipped.

The native job successfully completed legacy mechanics, repair, options, full audit and compatibility phases, including their separate-process restarts.

It failed when executing the `legacy-routes` phase.

Investigate the full native logs and uploaded evidence.

In particular, inspect:

- `tests/character_completeness/native_launch.gd`
- `tests/character_completeness/prestige_driver.gd`
- `tests/character_completeness/fixtures/prestige-v15-records.json`
- `tests/character_completeness/verify-package.py`

There is a suspected fixture mismatch: the legacy-route loader checks `saved.rules_ref`, while the prestige fixture writer appears to persist only records and hashes.

Verify whether this is the actual failure before editing.

Fix the root cause. Preserve strict comparison of all 485 historical prestige-route witnesses, the original v15 rules pin and exact snapshot hashes.

Do not bypass or weaken the failed regression, suppress errors, remove the test, or alter historical pack data merely to achieve green CI.

Improve diagnostic output so a recurrence reports its precise cause.

## 3. Repair the current completeness report

The baseline v15 audit demonstrates 20/20 legal progression for all 32 base classes.

However, `docs/implementation/game126/current/REPORT.md` currently shows 0/20 verified levels for every v16 class.

Determine why matching v16 production-kernel evidence was not attached to the current report.

Regenerate the current coverage matrix and human-readable report using actual current-pack witness data, including prestige compatibility where available.

Ensure the report distinguishes:

- Legal level-20 advancement from interesting level-20 gameplay.
- Development fixtures from legitimately earned progression.
- Reachable prestige routes from thematically appropriate routes.
- Defined or selectable options from mechanically tested options.
- Automated testing from human player acceptance.

Retain the full source catalogue and unresolved entries.

## 4. Finish native Windows acceptance

Run all required Windows-only checks against the corrected exact head.

Verify the complete exported executable and package, including:

- Historical pack and save preservation.
- Existing GAME-32 combat invariants.
- Genuine skill check outcomes.
- Correct Archmage eligibility and negative tests.
- Legal class progression and prestige histories.
- Twelve representative characters earning XP through actual gameplay.
- Separate-process saved-game restarts.
- Real Godot screenshots.
- Correct immutable v16 content hash and package provenance.

Do not add Linux CI.

Create the complete self-contained Windows x64 playable ZIP, record its SHA-256, and verify its contents independently.

Do not claim success based solely on source tests or old successful workflow runs.

## 5. Complete publication

Update the GAME-126 assessment, audit matrix, continuation notes and delivery documentation with the actual final evidence.

Commit and push the corrective changes to the existing PR #117.

Review all changed files and current-head checks.

When every required check passes and the package has been verified, mark PR #117 ready and merge normally into `main`.

Do not force the merge, bypass required checks or silently accept failures.

Confirm the resulting merge commit and main-branch integration.

Update Linear GAME-126 and GAME-123, including the PR, Windows evidence, accomplishments and remaining limitations.

GAME-123 must remain open because the wider character-playability milestone is not yet complete.

## 6. Prepare the next development stage

Once GAME-126 is successfully merged, confirm that GAME-128 is the next priority.

GAME-128 concerns completing the currently thin spell and ability repertoires of existing supported classes, particularly their higher levels.

Do not implement GAME-128 inside PR #117. Keep the current PR focused on completing and validating the existing work.

Provide a concise final handover containing the merged PR URL, commit, Windows package, test results, actual character-completeness findings and the recommended GAME-128 starting scope.

**Success means completing and delivering the existing GAME-126 implementation correctly—not producing another unfinished branch or replacing verified work with a new approach.**