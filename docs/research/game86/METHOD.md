# What was tested—and what was not

**Research model, not the GAME-33 implementation.** Reproduce with Python 3.12+, no packages, network, canonical worlds or game saves:

```sh
python -m unittest discover -s research/game86 -v
python research/game86/run.py --workers 4
python research/game86/report.py
```

`report.py` verifies complete raw results and generates the results page, seeded walkthrough and labelled board diagram. `run.py` resumes validated atomic group checkpoints; use a new `--output` directory for an independent fresh run. `timing.json` describes the latest invocation, and `timings/` retains earlier measurements; timing is intentionally machine-dependent. See [runtime evidence and Linux runner requirements](RUNTIME.md). No Godot screenshots are represented as evidence of combat: no combat scene has been implemented. Diagrams are explicitly labelled research diagnostics.

## Shared test bed

Orthogonal square-grid movement and Manhattan range. No diagonal shortcuts, facing, elevation, animation, long rests, downed recovery, campaign persistence or actual feat system. Walls block movement and symmetric supercover LOS, including corner grazing. Units occupy tiles but do not block projectiles. Cover tiles give +3 ranged defence; this is an intentionally coarse stand-in for **directional** production cover. Generated cover is not directional. Spawn areas are clear; deterministic connectivity repair ensures every start and the central objective are reachable. Moderate/dense maps begin with 10%/23% wall probability plus 14% cover before clearance/repair. Measured wall counts accompany results; nominal percentages are not claimed to equal final coverage.

Damage is fixed per archetype, plus 4 on a natural 20. Natural 1 misses; natural 20 hits. All attacks use d20 + attack versus armour. Separate exact probability enumeration reports streaks and expected damage. Fixed damage is deliberate isolation of action economy; it cannot establish whether final rolled damage feels satisfying. No advantage/disadvantage, saving throws, resistances or damage reduction in the batch model.

| Kit | HP | Defence | Attack | Damage | Move | Range/reach | Initiative modifier |
|---|---:|---:|---:|---:|---:|---:|---:|
| Fighter | 34 | 15 | +7 | 8 | 4 | 1 | 0 |
| Rogue | 26 | 14 | +7 | 6 | 5 | 1 | +3 |
| Archer | 26 | 13 | +7 | 8 | 4 | 7 | +2 |
| Mage | 24 | 12 | +7 | 8 | 4 | 5 | +1 |
| Monk | 30 | 14 | +7 | 7 | 6 | 1 | +3 |
| Controller | 24 | 12 | +7 | 6 | 4 | 5 | +1 |

These are invented experimental values, not Pathfinder statistics or committed balance. Rogue precision adds 4 once per activation when beginning concealed or supported by an adjacent melee ally; this is an ally-threat **proxy**, not geometric opposite-side flanking. The concealed case tests an opening damage advantage, not detection or disappearing while watched. Precision is consumed on the attempt; final rules should use the clearer on-hit convention discussed in the recommendation. The experiment does not silently claim those omitted systems exist.

All baseline maps are 12×12, initial horizontal separation 8, maximum 24 rounds. Odd seeds rotate starts 180 degrees. Each side retains its class composition; this is spatial mirroring across sequential seeds, **not** a paired crossover reversing the same initiative roll. Individual initiative is one keyed d20 + modifier, fixed thereafter, stable identity tie-break. Alternating and team-block variants are separate comparisons, not mixed into core results.

## Complete candidate packages

**A:** one movement allowance and one main action, either order, one contiguous move. An ordinary move is up to stride; attack consumes main. Dash spends both for twice stride, no attack. Charge spends both for up to stride+2, straight clear orthogonal lane, followed by a reach-1 attack. It cannot charge around corners or through a unit. Disengage spends main, then ordinary movement avoids departure reactions.

**B:** two interchangeable actions, one stride or attack per action. Standing still permits two full-accuracy attacks. Charge costs both. Two moves are its dash. This is genuinely flexible AP, not a claim that every XCOM shot leaves another action available.

**C:** three interchangeable actions. Stride/attack cost one; second/third attack penalties −5/−10; cast/control cost two; charge costs two. Penalties apply to the charge's attack too. No cross-activation attack-penalty carryover. Two or three strides cost those actions; the A-only Dash command is not used.

All allow one reaction per round, refreshed at global round start in this toy. Leaving adjacent melee threat can provoke an attack; a qualified melee hit can instead spend an unused reaction to cancel a pending cast. Engaged ranged attacks take −4. Casting a radius-1 burst at range5 spends one of two focus and resolves at the caster's next activation, against the locked tile, hitting allies as well as enemies for16. Pending tiles are public; the policy penalises standing in them. The mage chooses this cast only when two enemies are clustered and no friend is in the area. It is not a universal duel nuke. Moving does not cancel a cast in this model. Death cancels it. The controller has two casts of Slow (−2 stride next activation); the Stun variant skips one activation. These control effects automatically land to expose an **upper bound on reliable denial**, not simulate a final save DC. Repeated Slow does not stack but can refresh later. Guard exists for a targeted regression test: spend main, reduce one adjacent ally hit by4 using the fighter's reaction. The batch policy does not choose Guard.

Three rounds of uncontested occupation within Manhattan distance1 of the central objective wins an objective map; the rounds need not be consecutive. Otherwise elimination wins. A timeout is recorded separately, never turned into a points/HP win. No revival, death-save, retreat or reward system is hidden in these results.

## Policy and information limitations

Deterministic policy v1 scores attacks, advancing into attack range, ranged spacing, known reactions, cover, telegraphed hazards and central objective distance. It can disengage instead of shooting. It does not search opponent replies, reserve resources for the next encounter, coordinate sophisticated focus fire, choose Guard or bluff. It sees all living combatants' current public-model positions and quantities. This **fully observed baseline is not a stealth controller or the production observation contract**. A separate illusion test proves a much narrower route/target observation boundary without exposing secret truth. A deterministic weak policy can systematically favour one kit; more seeds do not fix that bias.

RNG uses SHA-256 keys for initiative and each actor's attack ordinal. Identical commands replay byte-identical outcomes. The nth attack by a given actor shares a roll across variants, but after different actions this is no longer the same tactical event. Paired differences share seeds and maps, not a guarantee of perfectly matched causal counterfactuals.

## Metrics and denominators

- **Contact:** the melee actor's first activation with a legal attack plan, including a move+attack or charge. It is an opportunity, not a hit, and does not require the policy to choose it. Routes that would provoke a reaction still count; the opportunity is not a promise of survival. Dead or timed-out units without a chance are censored, not assigned round24.
- **Pre-contact exposure:** ranged attack attempts and hits targeting that melee actor before its first recorded opportunity. Includes exposure to melee actors that never get contact; count and censoring appear alongside observed contact averages. Burst/control are separate metrics, not falsely counted as attack rolls.
- **Walking-only:** activation used only move/dash. Some are tactically useful—occupying an objective or avoiding a telegraph—so this is **not** a measured boredom rate. Idle and denied activations are separate. No claim that every attack turn is interesting.
- **Duration:** completed round index, including incomplete final rounds and timeouts. Six-person turns need separate decision/animation timing before claiming a minute duration.
- **Control:** actual denied/slowed activations plus same-seed alternative outcomes. Illusion diagnostic counts route detour, costly disbelief and decoy attacks; no invented damage-prevention number.
- **Uncertainty:** Wilson95% intervals on left-side win proportions; a timeout counts as not winning but remains separately reported. At128 samples a near-even proportion has roughly ±9 percentage-point uncertainty. These intervals do not represent map/policy/class-design uncertainty.

Core experiment: 3 economies × 7 matchups × 4 terrains × 128 seeds = 10,752 battles. Additional geometry, feature-removal, initiative, control, lethality, rogue-context and six-person batches are enumerated in `run.py`; every seed is retained, including losses and stalls. No lucky seed is removed.

## Research boundaries

The lane diagnostic deliberately removes death and terrain to reveal an indefinitely sustainable spacing cycle. The illusion diagnostic compares observations and BFS routes, not combat win rates. Healing/expedition-resource/CT examples are explicitly arithmetic, not simulations. Elevation, corridor body-blocking, actual concealment, escape and directional flanking receive concrete designs and follow-up acceptance tests; they are **not** asserted to have been balance-tested here. Production implementation and human playtesting remain subsequent review gates.
