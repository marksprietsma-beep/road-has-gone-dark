# GAME-86 research assessment

Research only; no production combat implementation. Base: reviewed GAME-83 `bc6f301f6458f992a16c1a201a381376d536b80c`, whose implementation has green Windows/Linux regressions. The research PR will target `feature/game-83-production-ui-system-refactor` and will not merge any stack.

## Existing decisions and open questions

GAME-17 requires PF1e-inspired build depth, an FFT-like small square-grid battle, the same deterministic simulator for manual and AI control, and separate objective/perceived state. Its d20 initiative and move/standard/swift economy are explicitly engineering defaults rather than final balance decisions. GAME-81's persisted adventurers and GAME-84's expedition services are consumers of a future combat contract; neither should be rewritten here. No separate GAME-32–35 implementation specification was found in repository docs. Authenticated Linear access is unavailable, so ticket-specific assumptions come from Mark's brief and the accepted repository design, with a prepared Linear update at delivery.

## Critical approach

Range alone does not determine free shots: activation order, whether move and attack can be combined, retreat geometry, sight lines and the objective change the answer. A bounded map can conceal an infinite-kiting defect. A win-rate improvement can also hide two empty walking turns. Duel outcomes cannot establish party balance. Illusion value requires observation-restricted policy inputs, not a damage surrogate or an AI that reads secret flags.

Compare three complete research economies: move + main action; flexible two-action turns; and a constrained three-action alternative. Study CT/timeline separately before deciding whether its extra turn frequency is justified. Use published game mechanics as evidence of solved problems, not proof that transplanted numbers will work.

## Work and verification

1. Audit primary manuals/developer material and clearly labelled specialist/community references; record access dates, supported claims and unavailable sources. Summarise, never copy guide prose.
2. Build a standalone, deliberately simplified seeded analysis model under `research/game86/`. Test required duels and mixed parties on open, moderate, dense and objective maps. Run thousands of seeds, side/order swaps, map/range/movement/lethality ablations and a long-corridor kiting test.
3. Report first credible melee attack opportunity, pre-contact ranged attempts/hits, movement-only turns, fight duration, objective outcomes, timeouts and controller limitations. Separate identical-seed paired effects from arbitrary comparisons. Include explicit control/illusion and protect/escape diagnostics.
4. Validate deterministic replays, legality, LOS symmetry, reaction budgets, observations and metric denominators. The toy does not implement final PF content, production saves or Godot combat.
5. Recommend one V1 model with tunable numbers, class examples, a traced 3v3 battle, same-engine command replay, failure modes and conceptual GAME-32–35 contracts. Keep the design gate open for review.

Only `docs/research/game86/` and `research/game86/` will change. Existing untracked research is preserved. Production rules, gameplay, saves, canonical worlds and UI remain untouched.
