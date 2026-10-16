# Wave Five — final Windows verification

Final feature head `193e702f681c95257afe6812144bb3dbc6ecfd6c` passed all 13 required checks and the complete [dedicated Windows workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38843879866) before normal merge in PR #103. The implementation merge `0db418283bf2f32668760b872d5908fb944b4270` has an identical tree. All seven automatic integration workflows passed on that exact merge source:

- [GAME-112 Character Catalogue Wave Five](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441096): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [GAME-112 Character Catalogue Wave Four](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441164): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [GAME-112 Character Catalogue Wave Three](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441260): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [GAME-112 Character Catalogue Wave Two](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441063): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [Production Sandbox Windows Review Build](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441244): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [Verify GAME-83 Production UI and Native Distribution](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441170): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.
- [Verify Party and Production Expedition Native Distribution](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441162): **success**, source `0db418283bf2f32668760b872d5908fb944b4270`.

No new Linux CI, Linux review package, macOS validation or Linux merge gate was used. Later PR #104 changes only CONTEXT.md/two ADRs; this close-out changes only documentation/evidence. Do not describe those later SHAs as fresh runtime tests. Reuse the verified unchanged runtime with explicit source provenance.

## Actual native proof

The exact-source [Windows package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441096/artifacts/12026441509) passes 1662 mechanics, 46 separate-process exact character/battle snapshot, 565 earned/skill/rest and 4 earned cold-restart checks, all zero failures. Native proof and independent package audit are in evidence/accepted-main-windows-native.json and accepted-main-windows-audit.json. evidence/final-ci.json indexes the final feature checks and all seven merge-source workflows. The ordinary campaign earns 360 XP/9 cycles/36 objectives, explicitly chooses Abjurant Champion, separately saves a legal base-class decline, and resolves all seven supported noncombat skill outcomes. Development level-20 fixtures remain labelled and separate from earned progression.

Checks include channel hit/miss/concealment/zero physical HP loss, original spell/slot/action/RNG, illegal weapon/form/unknown/forged/range/blocked/exhausted actions; bounded saved rest retrieval without free slots/XP; all 32 new named spells and 30 variants of 10 new psychic identities; genuine 1–20 class tracks and hybrid prestige caps; all new prestige rank effects, feat gates, ancestry restrictions, owned creature actions/costs/growth, forms/physical attributes/equipment and magic suppression/reversion/expiry; deterministic replay and exact process restart. Optional earned prestige remains authoritative, never starting or automatic.

Compatibility includes installed historical pins, legacy saves, frozen GAME-32 oracle, migration, existing builder/core/progression/psychic/creature/opportunity and production input/render suites. Preserved source oracle receipt: 22,181/0; migration235/0 and6/0 cold; historical append-only9/0. Existing workflow sections reran on final implementation source and passed; earlier receipts are not renamed as newly generated tests.

## Genuine renders and reproduction

Creator54/0 produces36frames; campaign81/0 produces45frames at640×360,1280×720,2560×1440. Thirteen genuine development-host Godot/OpenGL images are committed under screenshots/. Runtime source is byte-equivalent to final Windows source; these are not claimed Windows screenshots. Advanced histories use isolated normal births, never replacement of earned histories. See evidence/creator-render.json and campaign-render.json.

Focused source command: `GAME112W5_TEST_ROOT=<fresh writable path> python tests/character_wave_five/run-tests.py`, with configured GODOT_BIN/helper. Native Windows command: `python tests/character_wave_five/verify-package.py` from a clean committed source and fresh output root. The native verifier refuses unsupported release targets, checks import/script errors/nonzero exit/timeout/pin/hash/source, launches production with empty PATH and no checkout helper, verifies exact cold restarts and archive integrity, and records SHA-256. Do not rerun successful unchanged expensive suites merely to inflate counts.

## Preserved historical failure evidence

Native705bfe3passed1591/42/565/4; initial9389f00passed1591/42/454/4. Earlier files remain historical; final1662/46/565/4proof is above. Failed onboarding38841017525 had a 120-second cold-import timeout and stale uploaded log; live UTF8 logs/retained timeout output/production600second import budget fixed the harness without weakening assertions. Failed38843368151 exposed Windows CP1252 stdout while echoing Node Unicode; explicit UTF8 console output and actual Unicode tests fixed it. Corrected final onboarding38843818019passed. Negative timeout/script-error/nonzero checks remain enforced. No failed workflow is claimed green, and no gameplay/pin changes were needed for these harness corrections.
