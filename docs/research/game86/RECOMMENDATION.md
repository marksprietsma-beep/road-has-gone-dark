# Recommended V 1: move + main, one shared reaction

**Choose candidate A for the first implementation slice.** Use fixed individual turns on a small square grid, a free movement allowance alongside one main action, a shared reaction, and scarce telegraphed magic. These are concrete starting values for review and playtesting, not a claim that the research kits are balanced. The research Python simulator remains a diagnostic; implement the accepted contract independently in the game's shared rules engine.

## Initial rules and numbers

| Item | Initial value / exact rule | Evidence status |
|---|---|---|
| Board | 12×12 orthogonal tiles; initial separation 6–8; 3v3 first, up to 6 per side by encounter contract | 12×12 gap 8 core tested; geometry/6v6 sensitivity also run |
| Terrain | Two independent approach routes, useful LOS blockers and cover; validate actual connectivity and measured density; avoid a universal straight charge lane | Generator connectivity tested; authored layout quality needs human review |
| Order | Roll keyed d20 + initiative once; stable unit-ID tie break; one activation each round, public queue | Tested; tie/side crossover remains a follow-up |
| Turn | Move up to stride in one contiguous segment, plus one main action, either order; no generic swift/bonus action in V 1 | A tested; explicitly revises GAME-17's provisional swift default |
| Move / attack | Orthogonal cost 1; no diagonal/corner squeezing, no occupied destination; range in Manhattan distance; symmetric supercover LOS | Tested |
| Dash | Spend move + main, move up to twice stride, no attack | Tested |
| Charge | Spend move + main; straight clear orthogonal lane; travel at most stride+2; finish at reach 1 and make one attack | Tested; cannot bend around cover or pass through units |
| Disengage | Spend main; ordinary movement this activation ignores departure attacks; no ordinary attack remains | Tested |
| Reaction | One per actor per global round; refresh at round start; leaving a living enemy's adjacent melee threat may spend its reaction to attack before the departing step | Tested. Same budget must cover guard/interrupt; no simultaneous free extras |
| Ranged contact | −4 attack while adjacent to an enemy melee threat | Tested |
| Cover | +3 defence against a ranged attack whose line enters the target through a protected edge; full walls block LOS | Batch +3 tile-cover proxy tested; directional edge rule is **proposed**, not simulated |
| Accuracy | d20 + attack vs defence; natural 1 misses, natural 20 hits; critical adds 4 damage; fixed weapon damage for first debug slice | Tested. Rolled damage is later tuning, not a hidden second damage roll |
| Delayed burst | Main +1 Focus; range 5, radius 1 Manhattan; locked public tile; 16 damage to everyone in area with LOS at caster's next activation start; two Focus initially | Tested as unsaved upper-bound damage, not approved final spell balance |
| Interruption | An adjacent melee hit may consume attacker's still-unused reaction to cancel pending burst; dead caster loses pending burst; moving caster does not cancel | Tested. UI must disclose that an opportunity attack that already spent reaction cannot also cancel |
| Slow | Main +1 Focus, range 5/LOS, −2 stride for target's next activation, minimum 1, no stacking | Batch automatically landed. **Propose** Will d20+save vs DC12; this saving-throw version needs separate validation |
| Hard stun | Exclude full-activation stun from common V 1 player kit; preserve a condition hook for exceptional later content | Automatic stun studied as an upper bound; one denied actor is 1/3 of a three-person team |
| Objective | Three rounds of uncontested occupation within radius 1 of centre, cumulative; elimination also ends battle | Tested. Production scenario defines objective explicitly |
| Research limit | 24 rounds reports timeout distinctly | Tested. Do not ship “higher HP wins at timeout”; GAME-33 must specify retreat/stalemate outcomes |
| Focus persistence | Start expedition at 2; spend across encounters; replenish only on explicit eligible rest, not each battle or reload | Resource arithmetic only; expedition integration not simulated |

Initial level-equivalent debug kits (original research values, **not class progression tables**):

| Kit | HP | Defence | Attack | Damage | Stride | Range | Initiative |
|---|---:|---:|---:|---:|---:|---:|---:|
| Fighter | 34 | 15 | +7 | 8 | 4 | 1 | +0 |
| Rogue | 26 | 14 | +7 | 6 | 5 | 1 | +3 |
| Archer | 26 | 13 | +7 | 8 | 4 | 7 | +2 |
| Mage / illusionist | 24 | 12 | +7 | 8 | 4 | 5 | +1 |
| Monk | 30 | 14 | +7 | 7 | 6 | 1 | +3 |

Keep these as visible tuning data. The archer/mage duel failures make ranged policy and protected-position testing the first tuning priority. This recommendation does not certify that these initial HP/damage values should ship unchanged.

## Fighter: credible frontline without compulsory aggro

The fighter should normally win a clean sustained toe-to-toe fight against an equally advanced rogue. More HP and armour buy time; the research open fighter/rogue win rate is 87.5%. That is an expected role direction, not a universal 87.5% balance goal. The fighter must also make the party safer: occupied tiles, chokepoints and a departure threat constrain routes without forcing enemies to attack an “aggro target.”

Start **Guard** at one main action, lasts until the next global round, and reduce one hit on an adjacent ally by 4 while consuming the fighter's reaction. The player chooses guard protection versus a departure attack or cast interruption. The targeted test exercises damage reduction; the batch AI never chooses Guard, so party wins do not measure tanking. Test a one-tile corridor, a second route, and two threatened allies; no unlimited protection or magical movement blocking beyond actual occupancy.

## Rogue: advantages need context, not equal open-duel armour

Use stride 5, concealment/positioning and **Precision +4 on the first qualifying hit of an activation**, requiring either an unrevealed opening or an adjacent allied melee threat. The batch consumed precision on the attempt; switching to on-hit is a proposed clarity change and requires its own regression/balance check. Ally-threat support is not opposite-side geometric flanking: do not add facing rules accidentally.

The concealed opening reduced fighter wins from 87.5% to 81.25%; it did not make the rogue a superior duelist. Dense ground alone did not reverse the matchup (fighter 89.84%). Objective play reduced fighter wins to 69.53%. Two fighters still beat fighter+rogue in 73.44% of the ally-support batch. These findings call for better contextual utility and policy, not an automatic rogue damage buff until every duel is even.

Propose **Hide** as a main action requiring broken enemy LOS or qualifying concealment, opposed detection from observer knowledge; no vanish-while-watched reset of precision. Escaping consumes disengage's main action; the extra stride helps create a gap but does not teleport through occupied tiles. Objectives, scouting, opening access, traps and escape must provide explicit mission value. Actual detection and escape were **not batch simulated**. A weaker toe-to-toe rogue can be useful without asserting that this toy already demonstrates it.

## Mage and illusionist: meaningful power with exposed timing

A mage should not trade ordinary attacks with a fighter as if it were another armoured martial. The open duels produce zero mage wins against fighter/monk. In those duels the greedy mage never chooses its clustered-target burst, so they do not test its signature power at all. Burst can hit allies, advertises its tile, consumes scarce Focus and can be interrupted; protecting a mage therefore creates a reason to position a frontline.

Do not respond with guaranteed instant room-clearing damage. Start with the listed burst, Slow and an observation-dependent illusion; evaluate spell choice, LOS, timing and resource conservation. The automatic-control experiment omitted saves, resistances and immunity and cannot validate a final DC. The proposed DC12 is a tunable first test value, not a fitted optimal threshold.

For the illusion slice, propose two alternative one-main/one-Focus features, range 5/LOS, duration 2 rounds, only one maintained illusion per caster: a three-tile apparent wall or one apparent guard. Neither creates physical collision, real cover or free damage. A sight-dependent observer initially receives a plausible presentation, not the secret `is_illusion` flag. Deliberate investigation spends a main action and uses Will vs DC12; direct contradictory interaction discloses the contradiction to that observer. A decoy attack spends the actual action before revealing its false target; a “target invalid” response must not be a free truth oracle. Apparent identity IDs stay separate from hidden physical IDs.

The demonstrated illusion diagnostic redirected four route steps, charged an investigation action, and retained a second observer's belief. It proves the boundary only; it does not measure expert illusionist value. Mindless is not a universal immunity to visual figments: tag sensory modes and mind-affecting patterns separately. Resistant/immune targets and successful/failed disbelief must be in the first shared-engine acceptance scene. No spell-system implementation is in this PR.

## Monk: mobility and access, not permanent caster shutdown

Stride 6 is 50% greater than the fighter's 4; initiative+3 changes order, not activation frequency. The open mage/monk result is 0% mage wins, and monk/archer is 100% monk wins: an exaggerated mobile-melee advantage under this policy, not proof of healthy monk tuning. Dense/objective terrain, a protecting fighter, hazards and LOS may matter more than more speed.

Use the common charge, disengage and one-reaction interruption rule. Do not add unlimited free attacks, guaranteed silence, a second reaction, or speed-driven extra turns. A monk who spent reaction on departure cannot also cancel a spell. A protected caster can force the monk to route around bodies or spend an action disengaging. Later limited-resource step/deflect features can express class identity, but should enter as separate costed abilities after this access/counterplay gate; no untested monk combo is claimed here.

## Ranged counterplay: approach should cost something, not the entire fight

Bow range 7, ordinary stride 4 and charge travel 6 create different threat envelopes: stationary attack 7, move+attack 11 on a clear route, melee ordinary move+reach 5, and straight charge threat 7. These are legal maxima, not guaranteed free shots. Ordering, retreat, obstacles, cover, objectives and body blocking decide which plans survive.

In A open fighter/archer the first observed opportunity averages 1.406 fighter activations and pre-contact exposure 0.594 attempts per melee actor; fighter wins 128/128. That proves contact is reachable here and also warns that this bow policy/kit is too ineffective to certify. On objective terrain exposure rises to 1.203 and fighter wins 89.84%; moving to win an objective need not be a “wasted” turn. Contact counts the opportunity before moving and can include lethal reaction routes; it is not damage dealt or guaranteed survival.

An unbounded equal-speed archer can shoot and retreat indefinitely without approach tools. A bounded board alone hides that defect. Dash gives up damage to gain ground; straight charge rewards finding a lane; a second approach path and LOS blockers limit permanent safe firing. Do not collapse every range to melee distance or silently forbid intelligent retreat. Conversely, a reachable isolated archer need not win half its fighter duels. Require useful protected ranged pressure, credible open approach costs and decisions for both sides before final class tuning.

## Healing, control and longer campaigns

Start the optional debug heal at main action +1 scarce charge for 10HP, range 1; do not grant it as an unlimited loop. Two incoming 65%-accurate eight-damage attacks average 10.4HP before critical effects, so healing alone is not invulnerability. The resource diagnostic uses that simplified 10.4 arithmetic; the exact critical-inclusive expectation would be 10.8. Which model a UI preview uses must be explicit. Healing/retreat across multiple encounters need actual persistent tests.

Prefer short movement/control effects over routinely removing one actor's entire turn. A three-person group feels a stun more severely than a six-person group. Slow's poor batch performance is partly its controller's opportunity cost: the right side wins only 8.2% with Slow versus 19.1% without control. Do not claim a “balanced debuff” from those numbers. A coordinating policy must know when an attack, route denial, protection or escape is the better main action.

## Follow-up gates before acceptance as production balance

1. Same-seed side and initiative swaps; preserve kit identity while reversing positions/order. Compare at least conservative and coordinating policies and inspect timeout/idle regrets.
2. Real observer-restricted stealth/illusion, save/resistance cases, guard/escape, directional cover and protected ranged positions; all manual/auto legal commands share one engine.
3. Human 3v3 tests with clear previews and two viable approaches: record perceived empty turns, reaction comprehension, time to decide and spell counterplay. Repeat selected 6v6 cases without assuming duel data scales.
4. Persistent encounter result, resources and injury/retreat consequences across reload; no combat implementation or migration until the separate GAME-32–35 contracts are accepted.
