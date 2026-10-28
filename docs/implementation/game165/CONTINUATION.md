# GAME-165 — verified delivery checkpoint

## Current state

Continue the existing `fix/game-165-sentinel-end-turn` branch. Do not create a replacement implementation or another class cohort. GAME-163 / PR #164 is already merged at `37082d881b765aea70a3eee3794ce1304ab108ec`; all 27 post-main Windows workflows passed. Readiness remains **45 COMPLETE / 5 PARTIAL / 0 BLOCKED**.

The Sentinel repair is implemented and its focused native Windows release **passed**:

- Tested source: `89553b0de704ea2073a0eb5b30a25e024fe654c3`.
- Native run: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042
- Windows build: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042/artifacts/12782383693
- Native evidence: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042/artifacts/12782892616
- Inner playable ZIP SHA-256: `a84ec95a1e44d4fcc62a25e0bc0d3928ce10121bae39add2f74e97e7ef221ec1`.

Actual exported-game phases: probe **35/0**, campaign **121/0**, independent cold **10/0**, historical compatibility **1,941/0**, historical cold **486/0**, frozen oracle **22,181/0** (checks/failures). Empty-PATH production startup, bundled AMD64 runtime, source/content pins, ZIP CRC, SHA and licence notices pass. Original native PNGs and independently audited receipts are committed under this directory. Later changes are documentation/evidence only; compare all runtime/test/export inputs with the tested source before reusing this evidence. **Do not repeat the successful native release for documentation changes.**

## Confirmed cause and bounded correction

Released-v33 Windows run **40607601617** passed 29 reproduction checks. End was enabled/focusable but entirely off-screen: x880 in a 640-wide logical viewport, x1056 at 905 logical width (1280 physical), and x1336 at 1280 logical width (2560 physical). Withdraw remained visible. Original engine End at zero action/movement legally activates the Sentinel. Long ability labels widened the body and an expanding footer spacer pushed trailing progression controls outside the viewport.

Only production change: `scripts/ui/first_adventure.gd` keeps End/Return first, utility controls next and spacer last; adds an exhausted-turn hint and explicit-defeat styling/tooltip. Gates, callbacks, animation timing, rules, RNG, XP, entities and save writer are unchanged. All immutable v1–v33 packs/pins and all other production scripts remain exact. The exporter adds one diagnostic scene; historical guards independently verify only the exact footer and QA-entry exceptions while retaining every original assertion.

The repaired source workflow **40609353500** passed 35/121/10 focused checks before the native release. Both use genuine Godot mouse input through original production controls. Campaign tests cover summon, End at 0/0, Sentinel movement/end, Knight/enemies/subsequent party turns, permanent Wolf coexistence, controlled exact three-boundary expiry, independent save/restart with predicted next-command equality, and deliberate-only retreat. Actual fullscreen uses the CI display at 1024×768 (PNG 1024×767); window captures are 640×360 and 1280×719, with a separate 2560×1440 control probe.

## Evidence boundaries

No private save/log was accessible. The sanitized public fixture uses legal level-one records and an approved authored 8×6 board, explicit order and public RNG seed. The baseline Arcane Bolt rolled 5 damage; later fixed/native fixtures match the reported 8 through original RNG. Neither the private seed/world nor a repair to its already-recorded defeat is claimed. Existing long-label clipping and humanoid creature-art fallback remain documented limitations.

One earlier repaired cold test passed full state/battle hashes but failed raw Dictionary pin equality because JSON numbers changed runtime type. Both complete pins are now canonicalized with `RulesJson.normalize` before exact equality; no fields, hashes or assertions were removed and no production persistence changed. Other failed development runs were fixture typing, placement and renderer-record setup errors; successful final evidence uses the corrected inputs.

## Remaining publication steps

1. Inspect the latest branch and existing PR before creating anything. Commit/push final delivery documentation, original PNGs and audit receipts only.
2. Publish exactly one focused PR against latest main, tracking #165 and #101 without automatic issue-closing keywords. Review the diff and historical guards.
3. Verify all required final-head Windows checks, merge normally when green, then verify actual post-merge Windows workflows. Do not rerun the successful full GAME-163 release or bypass failures.
4. Close #165 only after integration passes. Update #101 / GAME-123 accurately, keeping the character milestone OPEN and readiness 45/5 unchanged. No callable Linear connector was found; do not claim a direct Linear update without a tool result.
5. Report the actual merge/main SHA, Windows download/checksum, evidence and private-save qualification. Stop; no new cohort, browser, world or pantheon work.
