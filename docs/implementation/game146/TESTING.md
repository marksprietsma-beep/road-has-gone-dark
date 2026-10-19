# GAME-146 verification ledger

Windows-only gameplay execution. Local Python checks inspect source bytes, manifests, JSON hashes and negative source guards; they do not execute Godot on Linux.

## Focused gate

- First candidate `9d94deb`: Windows import passed. Run39183198502 failed at `real legal Scout displacement`: the development fixture sent `position` instead of the required `destination`, and selected an occupied party tile. No production movement failure or assertion suppression. Corrected to `destination:[0,1]` with a clear target lane.
- Expanded focused candidate `8bdf8f4`: run39183498956 passed import but failed the Knight miss fixture: a level20 attacker still hits the target with a die1 under frozen GAME-32 rules. Corrected to a lawful level1 attacker and a deterministic damage6 roll, retaining the hit/miss/protection assertions. No automatic-natural1 rule was added.
- Candidate `223b92d`, run39183789892: failed a test that incorrectly treated `suggested_choice` as advancement authority. The helper proposes drafts; `preview_advancement`/history replay enforce legality. Corrected to submit a well-shaped forged first-level prestige choice to the actual authority; no production gate was changed.
- Candidate `5bc4249`, run39184129534: the level20 Duelist miss fixture had the same die1 assumption. It now explicitly supplies a documented high-defence development target, leaving production critical/miss rules untouched.
- Frozen all19 files/manifest rows inspected unchanged. Original append-only source-projection negative guard:15 checks, zero failures. Manifest/provenance/760 source-occurrence validation passed.

The focused runner covers lawful1/8/20 development builds for Scout/Rogue/Swashbuckler/Knight; conditional fencing statistics; real hit/miss costs/effects; proficiency versus fencing legality; resource exhaustion/rest; real movement versus spent token; adjacent armed allied threat; repeated precision; Knight actual adjacent shared protection; qualified optional prestige routes and cold exact characters/battle/next command/RNG. Later additions must be verified on their own commit.

## Release gate (not yet claimed successful)

Dispatch GAME-146 Mobile Precision with `release=true` after focused native fixes. One complete Windows export includes current v20 mechanics/input, separately pinned v19 and v18 mechanics/cold restart, archived v16 repairs/compatibility, all32 base-class progression audit, three actual earned490XP/level8 Scout/Rogue/Knight histories, connected campaign combat and rest/cold restart, real production Godot captures, empty-PATH production startup and ZIP integrity. Native proof records exact source commit, pack pin, phase timings and archive SHA-256. QA executables are removed from the playable package.

Higher-level/prestige histories are lawful development fixtures, never claimed as earned level20. The earned primary campaign is preserved; connected combat uses a verification fork through the same writer.

## Manual review path

Extract outer GitHub artifact ZIP, then inner playable ZIP. Keep all helper/assets/licences beside `road-has-gone-dark.exe`. Fresh New Game uses v20; old saves retain exact pins. Create characters, complete ordinary opportunities, return home for advancement, enter Old Road/generated combat. With Travel Blade/light armour use Fencing Flourish: misses spend resolve without weakening/parry; hits apply effects. Scout must actually move before skirmish. Rogue needs a living adjacent allied melee threat. Knight challenge weakens and enables adjacent guarding, with one shared reaction. No full disarm/AI taunt is promised.

## First successful focused receipt

`e8701c8`, run [39184470585](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39184470585):549 mechanics checks and29 separate-process cold checks, zero failures; source guards15 zero failures; all19 pack byte/manifest pins unchanged. Candidate v20 hash at this receipt was `2bb84382e48e0cdb80785509e06eb86cbaf22101763fb219d2e497c52bd62b0b`. Later active-weapon finesse and extra talent/path tests require their own receipt; this success is not falsely relabelled as final source validation.

Superseded, still-running PR jobs on older commits were cancelled to release CI capacity. Current-head requirements were left intact. Failed focused attempts remain recorded above; no failed assertion was removed.

## Current production-code focused receipt

`03fc70a`, run [39184788280](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39184788280):582 native mechanics and33 cold checks, zero failures, including active virtual-weapon finesse suppression, talent choices/effects and actual Trickster precision/control. Pack hash `79fa1f89a785b37fe651d422755ac9634dbfef8e9b9f959bdc08f510ebba8483`. Exact focused receipts are preserved under `evidence/`.

The historical main129 receipt was downloaded and inspected (not rerun):15 zero-failure native phase receipts at exact main `a10f533` and v19. It is separately labelled historical. The active GAME-129 package verifier also requires the same archived-vs-default distinction already used by GAME-130/133: archived mechanics/audit remain v19, fresh earned/connected campaigns use the actual configured default. This narrowly fixes a stale expected-pin assumption before the v20 merge; it does not migrate campaigns or waive exact equality.

## First release attempt

`35cc2ed`, run39185176113: focused Windows checks passed again. Native production export completed, then the QA export correctly rejected the new GAME-146 entry point because it was missing from the explicit diagnostic allowlist. Added only `res://tests/mobile_precision/review.tscn` to that existing list; no wildcard or guard removal. No complete playable archive was published from the failed attempt. Re-run the release gate after this narrow packaging correction.

## Strengthened Scout feat acceptance

A source review after the582-check receipt found the Mobile Skirmisher assertion (`stride>0`) did not prove an additional benefit. Both its+1 training modifier and Scout's intrinsic+1 training modifier were subject to the same maximum-only stacking rule, making the feat inert for every eligible Scout. Candidate v20 now uses an additional untyped+1 stride, with an explicit player-facing explanation; no new feat or movement token is introduced. The strengthened regression compares otherwise legal with/without-feat histories, checks a real reachable-tile boundary and successful/rejected movement commands, and verifies the same-history v19 development fixture retains its original stacking.

Run39185531550 at `ded169d` was cancelled as superseded before publishing a package; its completed phase receipts are historical intermediate evidence, not a final release. Candidate v20 after this correction has hash `63e8860ab0e0910768824da471aed39d75d0f8e18fb5b549b0dd31df36d4723a`. All v1–v19 bytes and manifest rows remain unchanged. No public Windows playtest ZIP with the earlier candidate was delivered.
