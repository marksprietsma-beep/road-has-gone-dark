The original GAME-86 runner wrote one continuous archive and deferred summaries until the entire 19,456-battle suite finished. This research change profiles repeated decision work, caches equivalent board/path/tactical calculations, and saves each completed experiment group atomically so interruption does not discard completed simulations. All 209 groups retain their original sample counts.

The complete seeded results, raw records, timings and hashes are included alongside `SIMULATION-RESULTS.md`, candidate comparisons, an explicit move-plus-main recommendation with initial values, fighter/rogue/mage/monk/ranged-counterplay answers, an actual 3v3 command walkthrough, and separate GAME-32–35 contracts. The interpretation identifies weak-policy and composition effects; it does not treat toy win rates as final class balance.

Validation:

- 24 tests pass, including checkpoint corruption/staleness rejection, incomplete-write recovery, occupancy-cache validity and serial/parallel equivalence.
- All 19,456 battle results/final-state hashes match the unmodified pushed simulator at `4c98a33ee7cf4ea63dddb96c82716242884d49c1`.
- 418 battles covering every configuration also match complete event logs.
- Two fresh full runs and a full serial resume produce identical canonical artifacts.
- First full four-worker run: 72.858s under a four-CPU quota; the former hours-long runtime was not reproduced here. A later 153.441s repeat competed with baseline verification and is recorded separately.
- Report generation verifies archive hashes, every original group/seed count, and summaries reconstructed from raw rows.

Scope is limited to `research/game86/` and `docs/research/game86/`. No production combat or save changes. Linux runner locking is documented. Ranged duel failures, weak Slow choices, source-access limits, proposed untested rules and required human/policy/information-boundary follow-ups remain explicit review gates.

Draft research PR targeting `feature/game-83-production-ui-system-refactor`; do not merge. Linear update text is prepared in `docs/research/game86/LINEAR-UPDATE.md`; posting requires the authenticated connector that is unavailable in this environment.
