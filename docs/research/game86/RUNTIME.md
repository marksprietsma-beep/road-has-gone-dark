# Runtime investigation and checkpoint evidence

## What was measured first

Starting point was exactly pushed head `4c98a33ee7cf4ea63dddb96c82716242884d49c1`, not a rewritten simulator. The unchanged design contains 209 experiment groups and 19,456 battles. Initial profiling sampled an open duel, moderate 3v3, dense 3v3 under C, and 6v6 under C. Those four completed in 0.34 profiled seconds. The claimed hours-long execution from the other chat was **not reproduced here**; no process trace or timing checkpoint from that machine was available. There is no evidence supporting a claim that a particular group alone required hours.

A broader same-machine profile covers two seeds in **every** group (418 battles), comparing original and optimized execution in the same process. Full profile tables are retained under `research/game86/results/profile/`.

| Baseline hotspot | Calls | Cumulative profiled seconds | Meaning |
|---|---:|---:|---|
| `choose` |13,542|11.130|Dominant decision work, including child calls|
| `position_value` |557,572|4.024|Repeated scoring for shared move/dash destinations|
| `dataclasses.asdict` |80,179|2.232|Generic recursive copying, including public observations|
| `Board.paths` |13,097|1.879|Repeated BFS for move/dash/contact and unchanged occupancy|
| `observe` |13,542|1.556|Mostly nested inside `asdict` work|

These cumulative values overlap and must not be added as independent costs. Pathfinding was worth eliminating where repeated, but was not the largest component. Observations and tactical scoring also mattered. The original runner's reliability defect was architectural: it kept one gzip stream open across all battles and wrote summaries/timing only after the final group; an interruption could leave no durable, indexed completion record.

## Equivalence-preserving changes

1. Move/dash options share one maximum-budget BFS; the shorter-budget options filter the same breadth-first discovery prefix. Original neighbour order and tie-breaking remain intact.
2. Immutable Board neighbours are cached (32,768 entries). A bounded 256-entry reachable-path cache keys on immutable board, start, budget and **frozen occupancy**. It returns a read-only mapping; a move/death produces a different key. Existing LOS caching remains. No policy result is cached across mutable combat observations.
3. Each decision memoizes destination position values and whether the actor can hit from a position. Attack scoring, rounding and command tie order are unchanged.
4. Public observations copy scalar/tuple Unit fields and explicitly copy the nested pending-cast dictionary, avoiding generic recursive dataclass traversal. Tests mutate both HP and pending-spell observation fields and confirm no authoritative mutation. This shortcut is valid for the current research schema, not a generic deep-copy promise for future nested fields.
5. Complete experiment groups run in isolated processes; workers never share mutable battles or RNG. Consolidation follows the **original case order, then ascending seed**, regardless of worker completion order.

On the 418-battle profile, baseline elapsed 15.242s versus optimized 12.303s: **1.239×**. Position evaluations fall 557,572→455,244; actual cached BFS misses are 5,441 versus 13,097 original traversals. Profiling overhead and warm caches matter; this ratio is not a claim that the unknown earlier hours are now reduced by a particular factor.

## Durable execution and restart

Each completed group writes a same-directory temporary file, flushes/fsyncs it, atomically replaces its named checkpoint, then fsyncs the directory. The JSON contains source/design identity, ordered raw rows, row SHA-256, summary and group wall time. Resume checks identity, row count, exact group/seed sequence, checksum and reconstructed summary before trusting it. A stale/corrupt checkpoint fails rather than disappearing from the sample. An incomplete temporary file is ignored.

A kernel file lock prevents two runners writing the same output directory and releases after process death. Only completed groups are promised durable: interruption can require rerunning the currently incomplete groups (at most one per worker), not the completed suite. The first clean full run's slowest group was 12.814s, so these group boundaries are already practical. More granular seed checkpoints were unnecessary for the observed workload.

Default invocation resumes all 209 groups; `--group` is an explicit prefix filter for operational sharding. A partial shard reports `PARTIAL`, never emits a fake full-suite result. Final artifacts are consolidated only with the complete original design. Gzip has fixed mtime and no embedded filename. Timing is excluded from deterministic result hashes; per-invocation timing is preserved under `timings/`, while `timing.json` describes the latest invocation (which may be a fast resume).

The runner uses Python standard-library `fcntl` locking and was validated on this Linux cloud machine. The simulator itself has no new external dependency; Windows execution of the runner requires a tested equivalent lock implementation rather than pretending `fcntl` is portable.

## Recorded completion and validation

- First fresh full run: **19,456 battles,209 groups,72.858s,4 workers**. Host exposed 5 CPUs; cgroup quota was 4 CPUs. Checkpoints were pushed during execution (first result commit `126368b`).
- Second fresh full run: **153.441s**,4 workers, while a separate 4-worker full baseline comparison competed for the same 4-CPU quota. This is a contention/repeatability run, not evidence of a runtime regression. Every canonical artifact hash is byte-identical to the first run.
- Original pushed simulator rerun: **all 19,456 results and final state hashes equal**. Comparison wall time 150.307s under the same contention. Do not use these competing-process timings to infer an isolated speedup.
- Full-event equivalence: all 418 representative battles (every configuration) have identical entire event logs and results, not merely wins.
- Full serial resume:209 groups reused,0.926s, all canonical artifact hashes unchanged.
- **24 tests pass**, including existing simulator/diagnostic tests, cached-occupancy invalidation, read-only paths, detached observations, full design counts, serial/parallel group equivalence, incomplete-write resume, stale/corrupt checkpoint rejection and unmatched-prefix handling.

The fresh repeat also exercises a runner error-path fix: an unmatched group prefix exits cleanly. That source change invalidates old checkpoint identities, so fresh repeat checkpoints—not silently relabelled old checkpoints—are committed as the current resumable set. Original invocation timing remains retained. The combat algorithm and experiment design did not change between the fresh runs.

No sample was removed. Identical baseline configurations exist across initiative/control/lethality/rogue families; they are documented as statistically duplicate evidence, but were still executed and retained as scheduled. The most expensive groups were multi-unit, longer A-economy runs; none justified revising the experimental coverage.

## Reproduce

From the repository root on Linux with Python 3.12+:

```sh
python3 -m unittest discover -s research/game86 -v
python3 research/game86/run.py --workers 4
python3 research/game86/report.py
# Repeat into a NEW directory to independently execute every battle:
python3 research/game86/run.py --workers 4 --output /tmp/game86-fresh-run
# Operational shard; it explicitly remains partial until every group is present:
python3 research/game86/run.py --workers 2 --group core/A --output /tmp/game86-shards
python3 research/game86/run.py --workers 2 --output /tmp/game86-shards
# Original-code comparison; git must contain the pinned starting commit:
python3 research/game86/verify_equivalence.py
python3 research/game86/verify_full_results.py --workers 4
```

Use a new output directory when source/design identity changes. Do not edit identity fields to reuse stale results. Running the report verifies hashes, all original seed counts and summaries from raw data; it does not rerun battles. `profile/repeatability.json`, `profile/equivalence.json` and `profile/full-equivalence.json` preserve the validation evidence. Current raw archive SHA-256: `d1ddec220972044b738bb7fbf6903f47ffe06ac28f4f507552e3210aec73eec0`.
