# GAME-97 verified integration delivery

Integration PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/75

Integration strategy: one non-squashed merge of final GAME-96 into current main, preserving both ancestries. No intermediate four-provider production state. Runtime/export provider LPC only; historical comparison originals/evidence/credits stay in repository/history. No combat mechanics, generation scope or character identities changed.

## Updated self-contained Windows review package

[Download Windows x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38037735342/artifacts/11665465069) · [native test evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38037735342/artifacts/11664544619)

Build source: `ae9c10ecde2c6bb23250ffbc57b3c0073e01c7d4` (same production scripts/data/scenes/tools as final source; later commits fix only negative-probe cold import and record audit). Workflow 38037735342 succeeded. Inner ZIP `game96-sandbox-windows-x64.zip`, 120,021,786 bytes.

SHA-256: `5042edbacd2269cccda59efad4a38a2f73ffc2ea77e62d728c9875d6e281195b`.

1. Download the GitHub artifact while signed into GitHub. Extract its wrapper ZIP.
2. Extract the enclosed `game96-sandbox-windows-x64.zip` completely. Open its game96-sandbox-windows-x64 folder.
3. Run `road-has-gone-dark.exe`; keep `worldgen-helper` and `artwork` beside it. No Godot, Node or separate artwork installation is needed. Escape skips the intro.
4. New Game → generate/select world → origin/state → region → hometown → confirm → inspect the three LPC sprite previews → Party ready → Enter hometown → Explore local opportunities. Inspect an available opportunity → Set out → Scout a rumoured lead → Travel → Engage occupants.
5. Move then click a dotted tile; Attack/class ability then a highlighted target; End turn. Main menu/Resume Expedition must restore exact battle progress. Victory or Withdraw → Return to regional play → Return home & rest. Try another opportunity; completed attempts stay recorded, and reward/history are applied once. Existing Old Road saves remain resumable; it is not mandatory new gameplay.

The four-style selector/F7 are intentionally retired under the LPC-only product decision. V0 rest/XP and small inferred/generated encounter scope remain unchanged.

Independent package audit: ZIP CRC; AMD64 game and bundled Node; 291 original LPC source hashes and required notices; no QA executable; one LPC style; no external comparison-provider files. Loading the Windows executable's embedded resource pack with matching Godot also confirmed all three obsolete provider directories and 422 historical imported-texture paths are absent.

Native Windows proof: 237 legacy journey assertions plus 294 generated-journey assertions, empty PATH and no source-helper override, two victories/one withdrawal and persisted consequences, preference restart, real production launch. Human Windows desktop/GPU review remains unperformed; actual rendered screenshots are from Linux Godot/Mesa/Xvfb, not fake or native Windows GPU captures.

## Known reliability boundary

GAME-99 remains separate: real extra seed `game96-sandbox-review-v2` fails source geography extraction with `Bad Azgaar packed vertex position 9109` before sandbox creation. GAME-96 preserved the original failure evidence; integration does not rewrite Azgaar or claim every arbitrary seed works. Tested preset/fresh-world suites and sandbox corpus have no such failure. GAME-19/85 town/facility research and GAME-98 icon integration remain backlog.

## Verification and integration route

Exact tested source head: `61eaa5bc31857dae4dd3811e2d85d4019ff47627`. All 12 workflows succeeded: 21 executed test/build jobs passed. The separate World Library `review-packages` release-publication job is intentionally skipped on pull requests; no required regression/test job is skipped. The additional updated Windows review build at `ae9c10e` passed (one native job). Later source commits change only diagnostic probes/audit, with no production scripts/data/scenes/tools differences.

The delivery commit contains only this directory's documentation and already-generated evidence and uses `[skip ci]` to avoid rerunning the entire matrix for reports/images. `git diff --check`, JSON/evidence hashes and a docs-only diff are checked before committing. This does not skip or bypass a failing source test: every source workflow above has completed successfully. Normal main push checks run after the merge.

The actual merge SHA, production PR dispositions and final main SHA are confirmed through GitHub in #75's final delivery comment; they cannot be precomputed inside this pre-merge commit. Historical closures #35–47/#60/#62 are confirmed; #51–55/#61 deliberately remain open research. #71–74 are replaced through this single integration, with their branches/history retained.

### CI workflow evidence

| Workflow | Result | Run |
| --- | --- | --- |

| Verify GAME-32 Rules Core and Native Distribution | Success | [run 38038342727](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342727) |
| Verify GAME-83 Production UI and Native Distribution | Success | [run 38038342745](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342745) |
| Verify GameWorld save foundation | Success | [run 38038342766](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342766) |
| Verify Hierarchical Origin Profiles and Native Distribution | Success | [run 38038342700](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342700) |
| Verify Local Region Generator V1 | Success | [run 38038342717](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342717) |
| Verify New Game origin | Success | [run 38038342747](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342747) |
| Verify Origin Context | Success | [run 38038342758](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342758) |
| Verify Party and Production Expedition Native Distribution | Success | [run 38038342722](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342722) |
| Verify Production World Enrichment | Success | [run 38038342756](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342756) |
| Verify World Library | Success | [run 38038342739](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342739) |
| Verify atlas landmark icons | Success | [run 38038342746](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342746) |
| Verify landmark inspection | Success | [run 38038342726](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38038342726) |

### Fresh local and native evidence

- Local full Linux GAME-83 `--visual --regressions` passed, including two presets/five fresh worlds, 336 expedition outcome sets/2,822 checks, source/party/origin/library foundations, 230 direct expedition checks and 468 inherited GAME-83 checks, plus 114 origin/party and 28 list-visibility checks.
- Fresh GAME-96 corpus and native Windows corpus match the committed GAME-96 metrics exactly: five worlds, 45 hometowns, 180 encounters, 178 configurations, 25,111 checks, 6,925 commands, zero failure or stall. Restart/duplicate outcome/source-pin/write rollback probes passed.
- Fresh actual Linux rendered journey: 331 assertions; all three target resolutions; three generated sites; two victories and one withdrawal; persisted history/XP/return; actual PNGs in evidence/. The inherited canvas produces 1280×719 raw images for the 1280×720 window; they are not padded or misrepresented. Linux screenshots use real Godot/Mesa/Xvfb, not simulated pictures.
- Native Windows legacy journey 237 assertions and generated journey 294 assertions, empty PATH and no source override; production executable launch/preference restart and all 291 original LPC source hashes verified. Only LPC is registered and bundled. Independent embedded-pack audit verifies absent historical provider textures too.
- Final GitHub Linux failure probes exit with expected failure in 1.37 seconds (assertion) / 0.76 seconds (offscreen target); full positive suite follows and succeeds. First repair attempt's cold-checkout inheritance failure was investigated and fixed by explicit project import, not ignored. Original failing run 37956679299/37956679358 and superseded-run cancellation records remain traceable.

Screenshots include licensed LPC artwork: see `assets/combat/LPC-CREDITS.txt`, `data/art/lpc-sources.json` and the bundled artwork notices for per-part credits/licences. Terrain is original project artwork; regional notices retain MIT Town Forge and CC BY 3.0 Game-icons attribution. No historical source asset/branch or research dataset is deleted.

See [AUDIT.md](AUDIT.md) and [PR-AUDIT.json](PR-AUDIT.json) for every original open PR's dependency, immutable head, changed files and disposition. [ROADMAP.md](ROADMAP.md) records the remaining scoped work. Human Windows desktop/GPU playtesting and GAME-99 remain explicit limitations, not integration permission blockers.
