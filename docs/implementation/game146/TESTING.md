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
