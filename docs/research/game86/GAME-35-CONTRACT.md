# GAME-35 — tactical AI and auto-resolve through shared commands

Proposed ticket contract; depends on GAME-33 engine/observations and GAME-32 content. Auto-resolve is a controller of the same battle, not an independent win-probability shortcut. GAME-34 can visualize or replay its event stream.

## Inputs and outputs

`choose_command(observation, legal_public_options, tactics, policy_state, policy_version)` returns an ordinary engine command plus a concise rationale based only on those inputs. The policy receives detached observer data, not the authoritative Battle object, secret illusion flags, undiscovered enemies, future rolls or an oracle that answers hidden-target legality for free. Policy memory is explicit, deterministic and saveable.

Tactics must initially support aggressive/conservative choices, hold-position/ranged preference, protect a named ally, reserve expensive magic and a retreat HP threshold. Content uses common targeting/effect/cost descriptors; the controller must not depend exclusively on class-name exceptions. Keep stable option ordering and deterministic tie breaking.

## Tactical competence required for V 1

Evaluate legal attack/advance/retreat, LOS and useful cover, departure reaction risk, objective pressure, delayed area hazards including allies, protecting a pending caster, condition/illusion value and resource opportunity cost. Guard and escape must be actual candidates. A controller should sometimes decline Slow or an investigation when a higher-value urgent action exists. Avoid interpreting potential damage as the only utility: prevented attacks, route delay, objective time, survival and conserved Focus all matter.

A short planning horizon or explicit tactical features can be sufficient. Do not promise globally optimal play or train on the hidden truth. Before adding expensive search, profile and bound evaluations per decision; cache only information whose dependencies are explicit. An occupancy/knowledge revision must invalidate relevant movement/target calculations. Run shared immutable-board work outside inner option loops.

## Reproducibility and execution

Pin policy version, tactics and initial policy memory with encounter inputs. Serial/parallel workers operate on isolated battles, preserve case/seed ordering and emit the same canonical result/event hashes. Atomically checkpoint each completed experiment group and preserve raw rows, all timeouts and timing; validate cache identity and content hashes before resuming. Never silently lower sample counts, drop failed seeds or convert a zero-test run into success.

Production auto fast-forward skips rendering only. Store an explanatory ordered log and expose important resource/reaction/illusion decisions to the player; do not display the toy research win rates as calibrated player odds.

## Acceptance evidence

1. All selected commands are accepted by the shared validator or explain a legitimate stale-revision race; no free special-case AP/resources. Replaying AI commands through the manual/headless path gives identical events/hashes.
2. Two policies with materially different tactics are evaluated on paired seeds, same-seed side/initiative crossovers, objectives, chokepoints and open/dense layouts. Preserve losses, stalls and a decision-regret sample, not only aggregate wins.
3. A fighter protects a caster when appropriate, a rogue pursues a qualifying opening/objective, a ranged actor retreats when useful without ignoring cover/reactions, and a monk chooses access routes rather than permanent generic caster shutdown.
4. An illusionist's non-damage action changes a route/target/objective outcome under permitted observations. A resistant/disbelieving actor responds differently. Differential hidden-truth tests prove that identical observations produce identical policy choices.
5. Demonstrate resource conservation across three encounters and a rational heal/retreat/guard choice. Auto output commits once through the existing expedition owner; reload does not reroll.
6. Benchmark decision time and full-batch time on documented hardware; no repeated per-destination BFS. Simulate process interruption, resume checkpoints, and compare serial/parallel canonical hashes.

The research policy's near-total ranged duel losses and counterproductive Slow choices are known shortcomings to address, not target behavior to reproduce for “balance.” Policy upgrades are separate from changing engine rules; compare both so causality stays interpretable. No production AI is implemented by GAME-86.
