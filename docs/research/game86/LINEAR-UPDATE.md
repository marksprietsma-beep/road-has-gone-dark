# Prepared GAME-86 Linear update

**Delivery status:** research and result checkpoints pushed on `research/game-86-tactical-combat-model`; external Linear update is blocked because this environment exposes no authenticated Linear connector/binding. This file is prepared text, not a claim that an issue was changed. Leave the design gate open; do not mark GAME-32–35 implemented or merge any branch.

## GAME-86 comment to post

Resumed pushed head `4c98a33ee7cf4ea63dddb96c82716242884d49c1` without replacing the simulator or reducing the original design. Profiled tactical scoring, observation copying and repeated BFS. Added dependency-correct caches, atomic per-group checkpoints, source/checksum validation, resumable shards, and deterministic parallel consolidation.

Completed **all 209 groups / 19,456 seeded battles**. First clean four-worker run took **72.858s** on a four-CPU quota; the prior hours-long runtime was not reproduced here. Original-code comparison matches **every battle result and final state hash**; 418 comparisons spanning every configuration also match entire event logs. Two fresh complete runs and a full serial resume have identical canonical artifacts. **24 tests pass.** Raw rows, per-group checkpoints/timing, invocation timings and hashes are committed. The second complete run overlapped baseline verification and took 153.441s; do not compare competing-process wall times as isolated speedups.

Deliverables:

- [SIMULATION-RESULTS.md](SIMULATION-RESULTS.md): full core/geometry/ablation/initiative/control/lethality/rogue/6v6 results and limitations.
- [RUNTIME.md](RUNTIME.md): hotspot evidence, unchanged scope, cache validity, interruption/restart and determinism proofs.
- [MODEL-COMPARISON.md](MODEL-COMPARISON.md), [RECOMMENDATION.md](RECOMMENDATION.md): candidate A/B/C plus untested CT alternative; **recommend A**, move + main, one shared reaction, concrete stride/range/HP/action/resource values and fighter/rogue/mage/monk/ranged-counterplay answers.
- [WALKTHROUGH.md](WALKTHROUGH.md): actual seeded 3v3 commands, initial board and identical shared-command replay; includes a delayed burst that hits nobody.
- Separate [GAME-32](GAME-32-CONTRACT.md), [GAME-33](GAME-33-CONTRACT.md), [GAME-34](GAME-34-CONTRACT.md), [GAME-35](GAME-35-CONTRACT.md) scope/data/interface/acceptance contracts.

The toy policy is not final class balance: almost-total ranged duel losses, counterproductive Slow decisions, duplicate baselines, limited observation modeling and missing side/order crossover are documented. Proposed on-hit precision, directional cover, DC12 saves and production illusion durations are explicitly untested follow-up values. Retain the original comparative source audit and its access limitations. No production combat, save migration, gameplay scene or merge.

Requested review: accept or revise the candidate-A rules gate and the four implementation contracts; keep human playtests, observer-restricted illusions, protection/escape, policy comparisons and campaign persistence as explicit future acceptance evidence.

## GAME-32–35 follow-up comments

- **GAME-32:** proposal in `GAME-32-CONTRACT.md`: versioned builds/advancement/content, attached to existing character IDs; deterministic derived snapshots and additive save compatibility. Await review; no implementation completed.
- **GAME-33:** proposal in `GAME-33-CONTRACT.md`: one authoritative engine/validator, shared manual/AI commands, per-observer knowledge, reactions, persistence and idempotent campaign result commit. Await review.
- **GAME-34:** proposal in `GAME-34-CONTRACT.md`: readable budget/path/hazard/reaction previews and manual/auto switching at command boundaries, with no hidden-information leak or renderer-owned rules. Await review.
- **GAME-35:** proposal in `GAME-35-CONTRACT.md`: observation-only deterministic policy, protect/escape/resource choices, multiple-policy paired evaluation and resumable performance tests. Await review.

Link these documents from the pushed branch when posting. Actual issue IDs/status transitions were not read; do not invent them or auto-close downstream work.
