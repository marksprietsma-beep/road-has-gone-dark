# First Adventure V0 validation

Validated in the cloud workspace using Godot **4.6.3**, Node **24.19.0**, the project-compatible GAME-32 helper, and native OpenGL Compatibility rendering on Mesa llvmpipe under Xvfb. All checks below completed with zero failures. No Windows build or human assessment of encounter fun is claimed.

| Check | Assertions / result |
|---|---|
| Godot editor import | No parser/resource errors |
| Combat authority | 67 checks: all starting compositions, geometry, action limits, stale/out-of-turn orders, input preservation, actual Guard reduction/reaction, Opening Strike damage, Focus abilities, damage-driven defeat, withdrawal, full deterministic replay and dynamic-key JSON checksum regression |
| Real campaign creation | 20 checks: existing world/origin/party, additive identity preservation, expedition site, battle start, regional bypass prevention, checkpoint and expected uninterrupted victory |
| Separate-process campaign reload | 86 checks: exact paused state; every following action saved/reloaded; final hash equals uninterrupted run; one reward/history; stale/duplicate rejection; atomic final consequence; victory/defeat return; normal follow-up investigation preserves failure memory |
| Native UI walkthrough | 43 checks: actual fight button, three viewport sizes, Move/tile click, menu/resume, attack/ability/end-turn inputs through victory, regional result and hometown return |
| Existing GAME-32 kernel | 22,181 checks; frozen rules pin, RNG and snapshot oracle unchanged |
| Existing GAME-32 migration | 235 creation + 6 reload checks; old narrative party and active expedition preserved |
| Existing GAME-84 lifecycle | 89 creation + 25 reload checks on the two bundled worlds |
| `git diff --check` | Clean |

The 216 slice assertions are checks, not 216 independent encounters. Test AI victories demonstrate reachability and deterministic integration, not final class balance. The handwritten manual steps in [README.md](README.md#manual-playtest) are the next review gate for decisions, readability and pacing.

Reproduction:

```sh
GAME76_HELPER_ROOT=/workspace/.cache/game32/worldgen-helper \
python3 tests/adventure/run-tests.py --work-dir /tmp/trhgd-adventure --visual
```

The local cloud display bootstrap was verified without system file changes. In this environment add `/workspace/.cache/adventure-display/root/usr/bin` to `PATH` if `xvfb-run` is unavailable. The reusable environment draft now records that setup; saving the draft does not publish it.

[Raw logs and stage timings](evidence/results.json) include the final run: editor import 4.179 s, combat 1.218 s, campaign creation 19.337 s, restart/campaign checks 45.881 s, rendered walkthrough 54.568 s. Campaign stages include actual helper generation and save validation; these are whole-suite durations, not frame/interaction latency benchmarks.

Captured player screens:

- [Local site encounter](evidence/screenshots/site-encounter.png)
- [640×360 battlefield](evidence/screenshots/battle-640x360.png)
- [1280×720 battlefield](evidence/screenshots/battle-1280x720.png)
- [2560×1440 battlefield](evidence/screenshots/battle-2560x1440.png)
- [Victory](evidence/screenshots/victory.png)
- [Regional consequences](evidence/screenshots/regional-consequences.png)
- [Returned companion histories](evidence/screenshots/party-history.png)

Xvfb's software renderer reports that changing VSync is unsupported; the native render/input test completed. Audio is deliberately set to the Dummy driver for this graphics/gameplay check. Test campaign saves remain in the isolated work directory; no generated world/library/save or engine cache is committed.
