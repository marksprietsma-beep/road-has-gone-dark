# GAME-121 implementation assessment

Branch `feature/game-121-sustainable-adventures` starts at GAME-119 review head `05b093a`, incorporating investigation `2441a6f`. The parent branch and PR80/81/88 are preserved. GAME-119 publication still requires Mark clicking Publish draft PR.

The approved outcome is an ordinary, ongoing earned-adventure loop with noncombat rewards and legitimate prestige entry. The implementation extends the existing OpportunityAdventure transitions and OpportunityRecords ledger rather than replacing the rules engine, campaign writer, world generator or tactical authority.

## Engineering sequence and scope

1. Introduce optional `adventure_cycles` records and a new immutable `contextual-cycles-v1` manifest. Keep existing V1/V2 sandbox records, character packs v1–v9 and builder XP policies unchanged. Cycle generation uses canonical world/home/cell, cached local placements, report ordinal, saved party briefing and persistent location/threat history.
2. Reuse existing recovery/investigation/contested activity templates, weighted environment/route eligibility and verified battlefield generation. Add a visible primary Seek new leads action and an ordinary adventure journal. Standing original reports remain accessible before starting cycles; an existing campaign resolves those saved reports before extending. No active or unfinished report is replaced by a fresh cycle.
3. Full recovery/investigation/peaceful access/combat victory awards10 XP each once. Partial assessment, inspection, failure, withdrawal, travel/rest and seeking reports award0. Combat and objective completion share one terminal action and reward. New rewards never rewrite old zero-XP noncombat results.
4. Real saved skill totals offer deterministic noncombat checks using RulesRng in an independent report/character/skill domain. Successful recovery/investigation contributions save one provision; peaceful-access checks cost one instead of two. The party briefing is pinned when reports are prepared; a later cycle incorporates new advancement. No separate narrative rules engine or unsupported class power is invented. Broader GAME-105 skill/ability narratives remain continuation work.
5. New encounter data advances bandits through the existing legal class kernel to the ceil(mean party level), capped12. Initiative uses the original stable comparator and combat thereafter uses unchanged GAME-32/TacticalCombat. Greedy enemy AI remains basic, and appropriate high-level pacing/encounter breadth is not claimed solved.
6. Verify fresh production-service creation, earned Rogue2/Wizard3 -> Arcane Trickster1 and subsequent advancement, actual spell/power use, negative reward checks, original-pinned save extension and new-process reload. Run parent regressions and native Windows/Linux packages, then capture actual production scenes.

## Save and determinism decisions

Report-generation context is stored before play. New place/event identities are separate; geographic references remain canonical. Old threats remain in memory even when a later recovery/investigation produces another result at the same placement. Completed report bases and ledgers are retained.

Only the new namespace canonicalises string keys and the existing JSON round-trip representation of local presentation coordinates. Original canonical world geometry/fingerprints are not changed. A policy/source mismatch refuses to reroll or award rewards. Existing lock/journal commit and rollback own every change, including terminal combat and reward. Validation caches are keyed by full immutable cycle data, scoped events, world deltas and permanent character histories.

Early development checks demonstrated360 earned XP and prestige2 without injections; these are interim source checks, not final delivery/native acceptance. Development policy changes correctly invalidated an in-flight temporary test campaign. The v1 delivery policy is now frozen before publication; final source, native proof, screenshots, checksum and precise limitations belong in DELIVERY.md once verified.

## Boundaries

Character content stays11 core adaptations through12,4 prestige paths through5,30 feats,12 skills,27 scheduled choices,9 race families/14 heritages. The403/66/~283 programme remains open. This ticket supplies earned opportunities, not core13–20 mechanics, final ancestry breadth, equipment/inventory, settlement travel, companions/summons or a world simulation.

At10 XP per success, level6/12/20 require25/121/361 completed objectives from zero. Automated service timings are not human playtest durations. Native verification and human acceptance must be reported separately; no Linear update is claimed without an available connector.
