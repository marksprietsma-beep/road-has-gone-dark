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

The full local `tests/ui_system/run-tests.py --visual --regressions` run and Windows/Linux CI are still in progress at this evidence checkpoint. Their final results will be added before handoff. The targeted results above are completed runs, not inferred from CI.

Original GAME-84 baseline capture: 230 expedition checks and 42 origin/party checks, zero failures. The added assertions check visible keyboard focus, exact marker centres, hidden-site projection, footer bounds, list visibility and result scroll position while retaining the original capture flow.

Logs are in [logs/](logs/). Godot 4.6.3 rendered through Linux software GL; the harmless Xvfb V-Sync warning is preserved. [review-proof.json](review-proof.json) records exact source boundaries, persisted-record equality and screenshot hashes. The full campaign suite uses separate freshly generated worlds and owned saves.
