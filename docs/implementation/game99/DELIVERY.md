# GAME-99 delivery — geography repair and existing campaigns

Implementation/build source: **`47286f6dd3a9895022b819d86f239fb44a4b4a2f`**. Repair commit: `838e64560f9c11a8177df41656c0cea72d7a4dfa`. Base: `1263f146ad5422945b355869ab2d977f14e0a4ef`.

[PR #77](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/77) remains **draft and unmerged**. This delivery preserves the existing implementation; it adds no gameplay, generation recipe, character/save migration or combat-rule changes. The final delivery commit adds only files under `docs/implementation/game99/`; the downloadable executable/helper therefore still corresponds to the final implementation source above. Its helper files have also been independently compared byte-for-byte with that source (see [package verification](evidence/windows-package-verification.json)).

## Root cause and precise fix

The original pinned Azgaar pipeline successfully generated `game96-sandbox-review-v2`, canonical SHA `c9eb47dacfe4560df8cdd4bb128ab578ff2997e288c79665fb2cf9ab5791cbe1`. Our sidecar writer then incorrectly rejected genuine Voronoi vertex **9109**, `[722.0000000000003, 800.4226306386807]`, on a 1280×800 canvas. Boundary pseudo-points can produce finite circumcentres outside that drawing rectangle. [ROOT-CAUSE.md](ROOT-CAUSE.md) records the actual Delaunay triangle and real-cell references.

Writer and reader now share the source-geometry validator. It accepts finite valid off-map coordinates while rejecting malformed coordinates, dimensions, references, incomplete cell tables, degenerate/self-intersecting rings and rings that do not contain their source centres. Sidecar schema v1, coordinates, vertex identities/order, rings, source fingerprints and canonical serialization remain unchanged. Display clipping already existed and was retained; no source point is clamped or discarded.

Missing derived geography is reconstructed in private staging using the original seed and pinned source. Publication requires an **exact canonical replay SHA match**, valid geometry and checksum; the sidecar is published last. Existing valid caches are reused unchanged. Interrupted publication can retry; corrupt published caches and mismatched replay still fail closed. No second save writer was introduced.

## Completed regression evidence

The completed suites were reused rather than rerun for additional assertion counts. Raw worlds, sidecars, generator logs, timings and recovery fixtures are retained in the linked CI artifacts; selected original machine-readable reports are committed under [evidence/](evidence/).

| Requirement | Result / evidence |
| --- | --- |
| Previously failing world, two canonical fixtures, 30 additional independently generated seeds | **33/33 passed on Linux and Windows**, zero failures. Seeds: `game96-sandbox-review-v2`, `game-11-determinism`, `atlas-showcase-06`, and `game99-independent-00` through `29`. The atlas fixture's actual seed is `atlas-showcase-06`. |
| Finite off-map geometry / malformed rejection | 36 legitimate off-map vertices in six generated worlds accepted. Seven geometry tests and four cache tests passed, including invalid/nonfinite coordinates, references, degenerate/crossing rings, canonical mismatch and interrupted cache publication. |
| Local regions and geographical continuity | 231 hometown contexts, 195,433 real cell polygons, 582,887 neighboring-cell borders and 66 shoreline seam checks passed. Repeated regional generation matched; selected sites remained on owned dry cells. |
| World identity and fingerprints | All 33 source/geography hashes and all 231 regional identities/hashes matched across Linux and Windows. Both pre-existing canonical fixtures retain their original geography bytes. |
| Procedural sandbox and persistence | Windows corpus: 180 encounters, 45 hometown contexts, 6,925 accepted commands, 25,111 checks, zero failures; creation and independent-process replay passed. [Metrics](evidence/windows-sandbox-corpus-metrics.json). |
| Combat state and RNG | Frozen combat oracle and command/result/log/RNG comparisons passed; GAME-32 kernel: 22,181 checks, zero failures, plus migration/restart checks. Existing valid original-production campaign resumed midbattle with battle/party/RNG unchanged. |
| First Adventure / presentation | Original combat and campaign create/reload passed; GAME-83 presentation, LPC, GAME-95 battlefield/animation and preference restart checks passed in the Windows build workflow. All 291 distributed original LPC resources independently hash-verified. |
| Native Windows exported game | Old Road: 237 checks; generated failing-seed journey: 305; untouched originally blocked campaign: 129; **zero failures**, empty PATH and no source helper override. Production executable launch passed. |
| Linux checks | Geography/recovery, local-region generation, world library, save foundation, enrichment, hierarchical origins and party/expedition suites passed. See links below. |

Corpus execution times: **284.008 s Linux**, **295.453 s Windows**, excluding separate recovery/package phases. Per-seed and per-phase timings remain in [Linux summary](evidence/linux-corpus-summary.json), [Windows summary](evidence/windows-corpus-summary.json) and the recovery timing reports. Coverage uses the existing 1280×800 continents recipe with differing landforms and biomes; it does not claim additional generation templates.

Canonical fixture geography SHA-256 values retained unchanged:

- `game-11-determinism`: `86f288aa7cb2f73a20566c85abae76e037a5a92e470501fa26c1b505ae2756ac`
- `atlas-showcase-06`: `fc0d743d9f369e973095233e27323596c019c7471f80903e07e4b2a66d85d95a`

## Existing-save recovery

The tests archive original production `1263f14` and its original helper, create a genuinely blocked campaign, and hand that same save to repaired-source processes. The blocked, recovery and replay phases passed with 14, 18 and 73 checks respectively on each OS. A second valid original campaign was paused midbattle and survived the same version handoff. Campaign IDs, party IDs, immutable source fingerprints and existing save ownership were preserved.

The Windows exported-game test takes an untouched copy of the original blocked save through the production main menu, local region, opportunity, battle, victory, return and reload. [Native recovery proof](evidence/windows-existing-campaign-proof.json) records the original failing world's SHA and persistent party IDs; no source helper override or external Node installation was used.

## Successful workflows and retained raw artifacts

All runs below tested implementation source `47286f6`:

- [GAME-99 geometry and recovery — Linux + Windows](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496645). Raw [Linux artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496645/artifacts/11668996576), [Windows artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496645/artifacts/11669366074).
- [Windows review build and native exported-game verification](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049495261). [Native Windows evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049495261/artifacts/11669452853).
- [Party / production expedition — Linux + Windows](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496808).
- [Local-region generation](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496824).
- [World library](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496741).
- [Save foundation](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496712).
- [Production world enrichment](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496685).
- [Hierarchical origins](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049496683).

The initial geography CI failure was a test-harness race in shared decoration compilation on Windows and a cold-import problem on Linux. Commit `47286f6` serializes regional decoration validation and waits for cold imports while excluding Node-only dependency examples from Godot imports. Scope, seeds and assertions were retained; the production decorator was not changed.

## Windows download and checksum

**[Download the Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38049495261/artifacts/11669557653)** (GitHub sign-in may be required).

Inside GitHub's wrapper ZIP is **`game99-geography-repaired-windows-x64.zip`**, 120,198,306 bytes, plus its checksum file. SHA-256 of this **inner playable ZIP**:

```text
7196ed42e87199efc9499f6f5abd0ceca9dce4e21e59e0bb43cf4fc8e56a115c
```

The outer GitHub artifact digest is different: `718c3d837a8c54b6b5412f5bd509104f65beb4401fc9fd0de1c56e76081dd6e8`. Do not use it to verify the playable inner ZIP. Package CRC, both AMD64 executables, corrected helper hashes and 291 original artwork hashes were independently checked after downloading. Only the game and bundled Node executables remain; QA executables were removed. Godot, Node, assets and licence notices are included; no separate installation is required.

The playable artifact expires **9 November 2026**; raw evidence artifacts have longer retention. This is an unsigned review build, not a permanent release.

## Test your existing Windows campaign

1. Close any older running copy. Optionally copy `%APPDATA%\Godot\app_userdata\Road Has Gone Dark` as a backup; **do not delete or move the active profile**.
2. Download the artifact and extract GitHub's outer ZIP. Verify the inner ZIP with PowerShell: `Get-FileHash .\game99-geography-repaired-windows-x64.zip -Algorithm SHA256`.
3. Extract that **second ZIP** fully into a new folder. Keep `worldgen-helper`, `artwork`, notices and all other files beside `road-has-gone-dark.exe`; replacing only the executable leaves the broken helper installed.
4. Run `road-has-gone-dark.exe`. Press Escape to skip the intro if needed. Select **Continue / Resume Expedition** and your existing campaign. Do not choose New Game or recreate its world.
5. Enter the hometown/local region. Missing geography should replay from the existing immutable seed and pass the exact source fingerprint check. Existing world, hometown and three companions should remain yours.
6. Explore local opportunities, inspect one, set out, scout if required, travel and engage. Use Move and a legal tile; Attack/ability and a highlighted target; End turn. Finish or withdraw, return to regional play, then return home.
7. Exit and relaunch; resume again. The same party, discovered opportunities, completed results and history should remain. An existing active battle should resume its own saved state.
8. If your private world still fails, retain the exact error and current game log (`%APPDATA%\Godot\app_userdata\Road Has Gone Dark\logs\godot.log`) together with its source fingerprint. Do not reset the campaign to work around it.

## Remaining limitations and next direction

**The player's particular vertex 11702 has not been independently reproduced without their private world data.** Recovery is proven with genuine original-version generated profiles, not with that private campaign. Corrupt published geography, unavailable source pins and canonical replay mismatches remain explicit blockers rather than silently changing a world. Native Windows verification is automated/headless; a human desktop/GPU review of this exact package remains necessary. Earlier local visual captures were lost when the execution workspace was replaced; they are not claimed as included evidence.

V0 sandbox scope is unchanged: bounded opportunities and humanoid opponents, placeholder journey XP, and existing rest/withdrawal rules. See [PROGRESS-AND-NEXT-TICKET.md](PROGRESS-AND-NEXT-TICKET.md) for the proposed next ticket. No GAME-98 work or new research phase was started.
