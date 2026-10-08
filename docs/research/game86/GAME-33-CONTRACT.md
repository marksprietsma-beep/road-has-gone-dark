# GAME-33 — one deterministic combat authority

Proposed implementation contract, not production code or a claim that the Python research model already satisfies it. Depends on GAME-32 mechanical snapshots and existing GAME-7/81/84 identities. GAME-34 and GAME-35 must call this same authority.

## Encounter/state boundary

`EncounterSpec` pins encounter ID, seed, rules/content hashes, map geometry and objective, participant character IDs/snapshot hashes, positions, current HP/resources, and controller ownership. Validate placement, board connectivity, party-size contract and resource validity before starting. Preserve a hash of the input; do not derive hidden identity from a mutable display name.

Authoritative `CombatState` contains round/activation cursor, initiative queue, units/occupancy, HP/resources/conditions, shared reaction availability, pending spells, objective counters, RNG keys/counters, per-observer knowledge and event sequence. Real physical state and believed appearance are distinct. Saves/replays include pending effects and observer knowledge, not only visible positions.

Only the engine mutates this state. There is no second “auto damage” formula, renderer-owned HP or controller-owned legality. Fixed input plus the same ordered commands yields the same events and state hash independent of rendering, animation speed and manual/AI origin.

## Command contract

A submitted command identifies encounter, actor, expected state revision, action/ability ID, apparent target or target tile and ordered path. The validator checks turn ownership, actor status, known target handle, budget, resources, physical resolution constraints and rules version. Structured results distinguish:

- Publicly invalid command: no mutation, no resource/RNG consumption, stable public error such as insufficient main action.
- Valid attempt meeting uncertain/hidden information: commit the declared cost, then resolve interaction and observations. A decoy attack must not fail free validation with “illusion target”; a hidden blocker reveals only through the applicable encounter rule.
- Successful transition: ordered events, updated revision and canonical state hash. Death, reaction, interrupt and objective checks occur at specified boundaries.

Preview uses only the requesting observer's permitted information. It exposes known costs/range/reaction risk and explicitly marks uncertain outcomes. A privileged debug mode is separate and never feeds a player/AI policy.

## Required initial mechanics

Square orthogonal board, supercover LOS, directional cover; fixed d20 initiative; one contiguous stride plus main; dash/straight charge/disengage; one shared reaction; ordinary melee/ranged attack; guard; a delayed hostile/friendly-fire area effect; a short debuff with save; and an observation-dependent illusion with resistant/disbelieving targets. All numerical constants live in the reviewed rules pack (see recommendation), not hard-coded into controller branches.

For the initial reaction policy, resolve departures before each movement step in stable identity order. A reaction spent on a departure attack cannot additionally interrupt a pending cast. Guard, departure and interruption compete for the same single resource. Round-start refresh, guard expiry, activation-start pending cast resolution and condition expiry need explicit event ordering. Reaction choices may pause the manual flow; auto submits the same reaction command or a saved explicit default.

Win conditions distinguish elimination, scenario victory, defeat, successful retreat, draw/stalemate and unresolved research timeout. A research round limit is not permission to fabricate campaign victory. Propose a marked extraction edge with all surviving participating units extracted to count a clean retreat; partial retreat records who remains. Validate this separately—the research batch did not implement it.

## Persistence and replay

RNG must be versioned and independent of unordered container traversal, wall clock and process scheduling. Pin the chosen key/counter scheme; no Python `hash()` or global animation RNG. Ordered commands and relevant resolution events reconstruct the authoritative hash at every transition. Controller policy version belongs to replay provenance; different legal decisions may legitimately produce different outcomes.

Finish via a single durable result keyed by encounter ID and input hash. Commit HP, spent resources, injuries/retreat and declared reward consequences once through the existing expedition/save owner. Retrying after a crash returns the already committed result; reloading cannot reroll a resolved battle. Fail safely if participant/build/world references mismatch. Test crash boundaries around result staging and campaign commit.

## Acceptance evidence

1. A 3v3 seed plays headlessly, manually by a captured command stream, and through AI replay with identical events/hashes for identical commands. Save/reload halfway through a delayed spell and an illusion preserves the outcome.
2. Illegal paths/costs/targets and stale revisions do not mutate state; a valid decoy interaction consumes cost and updates only authorized observer knowledge.
3. Tests cover LOS symmetry, corner grazing, occupied corridors, cover direction, dash exclusion, charge lanes, shared reaction exhaustion, friendly burst casualties and death cancellation.
4. One observer changes route/target because of an illusion; another resists or disbelieves; physical collision remains correct. Show successful and failed checks and no omniscient preview leakage.
5. Guard/escape/control have measurable accepted scenario outcomes; the simulator does not equate usefulness with damage alone.
6. Same fixture runs with rendering disabled or accelerated without result change; all participants/resources remain valid. Campaign commit is idempotent across simulated interruption.

Out of scope: a full PF catalogue, vertical flight/facing simulation, CT initiative, production AI quality, UI art and adding these systems in the GAME-86 research PR.
