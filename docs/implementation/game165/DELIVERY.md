# GAME-165 — Sentinel End Turn repair

## Root cause and correction

Windows reproduction [40607601617](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40607601617) passed 29 checks and confirmed that End was enabled and focusable but outside the viewport, while Withdraw remained visible. Long ability labels widened the body; the footer's expanding spacer then pushed trailing controls off-screen. The existing engine already accepts End with zero action and movement and correctly activates the new Sentinel.

The repair keeps gold End/Return at the footer's left edge, utility and explicit-defeat controls next, and spacer last. A spent-turn explanation and warning-coloured Withdraw clarify the choices. Button gates, save threading, presentation timing and command callbacks are unchanged.

**Only `scripts/ui/first_adventure.gd` changes in production.** All v1–v33 data bytes/pins, every other production script, combat/RNG/XP/save authority, 50-career roster and **45 COMPLETE / 5 PARTIAL** matrix are preserved. The exporter adds one diagnostic scene. Historical guards retain all original assertions and independently verify this exact UI/QA-entry exception. No v34 or unrelated feature work.

## Windows playtest

[Download Windows x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042/artifacts/12782383693) · [Successful native run](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042) · [Raw evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042/artifacts/12782892616)

Extract the outer GitHub artifact ZIP, then **`sentinel-turn-windows-x64.zip`**. Keep the complete extracted directory and run **`road-has-gone-dark.exe`**. Godot, Node and artwork are included; no separate installation is needed. Escape skips the intro. Resume a campaign or use normal New Game. Historical rules pins remain exact. Artifacts are retained for 90 days and may require repository login.

SHA-256 of the **inner playable ZIP**:

```text
a84ec95a1e44d4fcc62a25e0bc0d3928ce10121bae39add2f74e97e7ef221ec1
```

Tested implementation/export source: **`89553b0de704ea2073a0eb5b30a25e024fe654c3`**. UI SHA-256: `5c3a5631bbd5d7b8121394e98b94f8cd748395da7fad016986b51de84212370c`. Subsequent documentation/evidence commits have no runtime/test/export differences. The successful GAME-163 full-class release was not repeated.

## Actual native results

These phases ran in the exported Windows game, except the separately identified existing frozen oracle:

| Phase | Checks | Failures |
|---|---:|---:|
| Production-control probe | 35 | 0 |
| Campaign controls and persistence | 121 | 0 |
| Independent campaign cold restart | 10 | 0 |
| Historical v16 compatibility | 1,941 | 0 |
| Historical cold restart | 486 | 0 |
| Frozen GAME-32 oracle | 22,181 | 0 |

Real Godot mouse input exercises the original scene/service/thread/save writer. A legal level-one Sorcerer/Knight/Ogre Druid/permanent Wolf fixture and two living enemies reconstruct revision 7, caster cursor 2, zero action/movement, a 12-HP Sentinel and three remaining rounds. End activates Sentinel; owned movement/end, Knight, deterministic enemies and subsequent party turns progress. Wolf and summon coexist. A separately controlled all-pass timeline proves exactly three global expiry boundaries without confusing defeat or owner death with expiry. Independent cold continuation preserves exact state/battle hashes, complete canonical pins, identities, resources, duration, log/RNG and predicted next command. Retreat occurs only after a deliberate Withdraw click.

The original executable also starts with an empty PATH and no source-helper override. The independent [archive audit](evidence/archive-audit.json) verifies CRC/SHA, 7,061 safe unique entries, AMD64 game and bundled Node, exact source/manifest/content, 121 licence/credit files and absence of the QA executable. [Native receipts](evidence/native-proof.json), [timings](evidence/native-timings.json) and [original screenshots](screenshots/README.md) are retained. All game validation was Windows-only; host ZIP/PE/hash inspection was static.

## Limits and player retest

Follow [TESTING.md](TESTING.md): after moving/casting, use gold End at the left footer and check Sentinel's own activation. Existing long ability-label clipping and humanoid creature-art fallback remain. Fullscreen ran on the CI display at 1024×768 (PNG 1024×767); requested 640×360/1280×720 windows rendered 640×360/1280×719. A separate control probe also rendered 2560×1440. No larger-fullscreen or human NVIDIA-driver acceptance is claimed.

**No private save/log was accessed or published.** The public reproduction uses an approved authored 8×6 board and explicit order/seed, not the player's private world. The baseline proof rolled 5 Arcane Bolt damage; later fixed/native fixtures match the reported 8 with original RNG and a public seed. A historical campaign already saved as defeat/returned-home retains that outcome and zero XP; this fix does not rewrite or reward it.

Readiness remains 45/5/0; GAME-123 / #101 remains OPEN. PR and post-main integration outcomes are recorded on GitHub #165/#101. No direct Linear update is claimed without a callable tool. Stop after verified integration of this repair.
