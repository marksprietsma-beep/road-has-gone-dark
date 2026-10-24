# Exact recovery checkpoint — upper-tier cohort in progress

Branch: `feature/game-123-sorcerer-druid-upper-tiers`, based on verified main `3e62d5cfc4959269f607ee7f64008842882f1c48`.

Prior gameplay/test source: `ae917f89e348038b478448b19ec33b3278686732`; the following fixture-placement commit supersedes it (use actual branch HEAD). Later documentation-only commits do not alter native inputs. Four original upper-tier choices and the existing capability gates, finite weapon-attempt interception, allied-form reversion and compact shell feedback are implemented. Immutable candidate27 hash: `1a129bb25bb4b3fea10e79de37436682eb594d4f59ae174620969a5e8a060a84`. All1–26 bytes/pins and frozen TacticalCombat remain unchanged; static source guard passes. No roster/world expansion.

## Current required next action

Focused run40048413027 on ae917 reached final saved-battle validation and rejected the companion fixture: it had been moved onto an ally's occupied tile. The fixture now uses the verified free0,1 tile and asserts validity before casting; final save assertions include the precise validator error. The next focused run must pass; inspect its actual current result before further release work. No successful native release, readiness promotion or merge is claimed. No PR exists yet; do not duplicate one if a later execution publishes it.

Prior focused failures were isolated and corrected without weakening invariants:

- 40046351371/source52858db: test-driver Variant type declarations, before mechanics.
- 40046702266/sourcefea6c2f: malformed Slowed fixture with remaining2 although its immutable duration is1.
- 40047139495/sourcea5475af: negative score fixture retroactively changed base scores and invalidated prior feats. Now builds a lawful low-casting20 history instead.
- 40047604548/sourcea79b9c6: a level7 Fighter cannot succeed against the highest tier9 DC. Upper save witnesses now use a lawful level20 Monk with real Reflex/evasion; lower-tier legacy witnesses remain unchanged. No DC/rules assertion was relaxed.

GitHub sometimes returns503 for combined logs/artifact downloads. Retry the read or use the preserved per-run evidence artifact; never relaunch expensive tests merely because metadata download failed. Credentials work with `env -u GH_TOKEN -u GITHUB_TOKEN GH_CONFIG_DIR=/workspace/scratch/game146/gh-auth gh ...`.

## After focused success

1. Confirm runtime/test/workflow/export inputs match the passing source. The dedicated workflow ID is394715811 (`verify-upper-nature.yml`), already registered/active by feature pushes. Dispatch `release=true` once stable, using this branch. Full native script, approved QA export scene, ordinary490XP/8 journeys, actual saved class-action combat, capture worker and source/archive audit are implemented. Do not rebuild them from scratch.
2. Complete native gate runs fresh27 mechanics/cold/controls/earned/connected/renders/all32 base20/current Wizard-Cleric and pinned26/18/16/compatibility/frozen22181. Inspect real failures first. Release uses empty PATH, bundled helper, checked startup and removes the QA executable.
3. Download `upper-nature-complete-windows-x64` and `upper-nature-windows-evidence`. Verify CRC/AMD64/source/manifest/content/canonical pin/credits/checksum with audit-windows-delivery.py. Preserve original PNG bytes and exact dimensions; 1280x720 requests may render1280x719. Clearly label upper20 as development fixtures; ordinary earned characters are490XP/8.
4. Generate readiness only from the matching successful receipt: `python tools/character-content/build-readiness.py --pack trhgd-character-v27 --native <native-root>`. New guard `readiness_upper_nature.py` preserves31 prior source-labelled acceptances, requires actual current contracts and only then promotes Sorcerer/Druid, targeting33/17/0. Do not force totals or claim every old career freshly accepted.
5. Finalise DELIVERY/TESTING/PR description, actual native/evidence/source/checksum, screenshot README and next-wave document. `game127-support/NEXT-WAVE.md` now correctly identifies the active cohort and31/19 baseline; after acceptance update it to the actual remaining hybrid queue. No next cohort implementation.
6. Publish one reviewable PR against latest main, inspect full logical delta, run/review required Windows checks, merge normally only when green, verify actual merge/main and post-merge workflows. Keep GAME123/#101 InProgress/OPEN; issue101 already has an active upper-nature marker. No callable Linear connector; never claim a direct Linear update.

All important source is pushed. Preserve incidental untracked __pycache__ directories. No Linux game validation, no force-push/check bypass, no silent save migration or extra content roster. Stop after this cohort.
