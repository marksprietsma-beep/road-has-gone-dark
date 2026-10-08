# Candidate combat-model comparison

Research decision proposal, not accepted production balance. The existing comparative source audit remains authoritative about what was actually read; no new source access is implied here. See [complete experiment results](SIMULATION-RESULTS.md).

| Candidate | Actual budget studied | Benefit | Cost / observed failure mode | Decision |
|---|---|---|---|---|
| A: move + main | One contiguous stride and one ordinary attack/control action in either order; dash or charge commits both | Repositioning does not forfeit an ordinary attack; one main effect per activation is easy to preview; defender gets a meaningful reaction choice | Dash can still be a walking-only activation. Weak ranged policy loses almost every open duel to mobile melee. Movement and ability targeting still need tuning | **Recommended V1 foundation**, with explicit counterplay and playtest gates |
| B: flexible two actions | Move or attack costs one; stationary actors can attack twice at full accuracy | Few budget types; clear choice to move twice | Standing still doubles ordinary attack opportunities. Encourages stationary exchanges and focus fire; dense party runs have 12/128 timeouts | Reject as default. A specific costly double-shot ability can be balanced separately |
| C: constrained three actions | Move/attack costs one; later attacks −5/−10; spells cost two; charge costs two | Movement can coexist with more than one action; smallest walking-only fractions in these tests | More command/preview states and marginal-attack arithmetic. Dense party runs still have 9/128 timeouts. Rounds are shorter partly because each activation has more work | Viable future alternative, not justified as first-slice complexity |
| CT / recovery timeline | **Not batch simulated**; diagnostic arithmetic only | Speed, equipment and heavy actions can have distinct next-activation costs | Speed can multiply both movement and action frequency; telegraph deadlines become harder to teach; 1.5× frequency ×1.5× stride is 2.25× travel per time | Defer until fixed-round version works; do not infer balance from FFT/TO inspiration |
| Team-block / alternating ordering | A budgets with separate scheduling batches | Team block supports coordinated turns; alternating bounds long enemy sequences | Neither policy coordination nor alpha-strike human skill is measured. Left win rates 91.8% individual, 90.2% alternating, 92.6% team are not a design verdict | Start with fixed individual d20 initiative and expose the queue |

## Why A despite the strong melee results

The goal is a comprehensible tactical decision per activation, not maximizing the weak policy's win rate or minimizing simulated rounds. A keeps the basic attack's cost stable while permitting movement, special commitments and a shared reaction budget. A's 3v3 moderate party lasts 7.461 rounds versus B 5.984 and C 4.531, but these are round indices, not play durations. The 91.4% A left-party win rate is a composition/policy warning, not the target.

The isolated A archer loses all 128 open fighter duels; the isolated mage also loses all 128 against either fighter or monk on open maps. An economy that permits contact therefore still requires ranged/caster encounter and policy work. No claim of class balance follows from choosing A. Require useful ranged contributions in protected formations and objective encounters, inspect failed retreat decisions, then tune range/defence/charge within this single chosen economy. Do not switch all actors to B merely to let stationary bows shoot twice.

## Decision criteria not measured by a win-rate table

Human predictability of legal plans; whether a novice can explain a lost reaction; viable protect/retreat/illusion commands; fairness of information; modest animation/decision time; build hooks that remain legible after multiclassing; campaign-resource pressure; and consistent manual/auto resolution. These are explicit implementation/playtest acceptance gates in GAME-32–35. No numerical weight fitted to the existing wins can substitute for them.
