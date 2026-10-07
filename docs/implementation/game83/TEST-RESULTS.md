# Executed verification

Tested implementation: `bfbdf48b4ae26dd1fc516cd8641177ee63fc4bd5`. Evidence-only commits follow this source commit.

| Executed check | Result |
| --- | --- |
| Original Back regression before correction | 109 checks, one reproduced failure |
| Original Back regression after correction | 109 checks, zero failures; original test unchanged |
| Added row-rectangle / Back / resize regression | 28 checks, zero failures |
| Shared presentation assertions | 20 checks, zero failures |
| Final real Godot origin/party capture journey | 114 checks, zero failures |
| Final real Godot expedition capture journey | 468 checks, zero failures |
| Complete before/after saved-record comparison | 14 records identical; one exercised campaign, 13 unchanged; no field exclusions |
| Screenshot manifest | 110 original captures with dimensions and SHA-256 |
| Project startup with actual renderer | Exit 0, no script errors |
| GAME-84 lifecycle create / independent-process replay | 324 / 85 checks, zero failures |
| GAME-84 cache integrity / failure safety | 15 / 32 checks, zero failures |
| GAME-84 actual outcome corpus | 336 cases, 2,822 checks, zero failures |
| GAME-84 source batch | 7 worlds, 105 regions, 840 sites; zero geography violations, knowledge leaks or determinism failures |
| GAME-84 cold/warm resume | All 7 worlds preserve campaign bytes |

Final CI run [37599062997](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997) completed successfully on **Windows and Linux**. The existing GAME-74/75/76/79/80/81/84 regression chain and GAME-7 persistence checks passed. Linux also completed the actual input/render chain and added GAME-83 captures/list tests. Windows completed source regressions and native packaged execution; Windows laptop visual acceptance remains Mark's review.

Both native packages passed **60 checks with zero failures**, exercising two presets plus a fresh world, an empty PATH, no source-helper override and the production release launch. The GAME-81 batch proof on each platform recorded 1,050 distinct character facts/prose combinations and zero contradictions, invalid source claims or hidden-information leaks. Exact artifact IDs, inner/outer checksums and native records are in [CI-EVIDENCE.md](CI-EVIDENCE.md).

The standalone local capture and targeted results in the table are completed executed runs. The additional local full-chain run was interrupted by the environment/turn change; its retained `game84-and-foundations.txt` log is partial and is **not** claimed as a complete local pass. The authoritative full-chain result is the completed CI run. No verification was rerun for this final documentation/publication pass.

Original GAME-84 baseline capture: 230 expedition checks and 42 origin/party checks, zero failures. The added assertions check visible keyboard focus, exact marker centres, hidden-site projection, footer bounds, list visibility and result scroll position while retaining the original capture flow.

Logs are in [logs/](logs/). Godot 4.6.3 rendered through Linux software GL; the harmless Xvfb V-Sync warning is preserved. [review-proof.json](review-proof.json) records exact source boundaries, persisted-record equality and screenshot hashes. The full campaign suite uses separate freshly generated worlds and owned saves.
