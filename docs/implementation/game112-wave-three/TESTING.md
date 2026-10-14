# Wave Three validation

The frozen GAME-32 oracle has passed locally: 22,181 kernel assertions, 235 migration-create checks and six separate-process migration reload checks. A first local attempt used the wrong helper environment variable and failed migration availability; rerunning with the existing `GAME76_HELPER_ROOT` directory corrected the environment. No oracle assertions were changed.

The candidate pack and mechanics remain under validation. Earlier candidate runs reached 545 checks with no mechanics failures; the new separate-process effect-result comparison exposed a hash mismatch and is being diagnosed. This is not yet a released or natively validated v13 pack. Historical v1–v12 are unchanged.

Run `python tools/character-content/validate.py`, then `GAME112W3_TEST_ROOT=<writable directory> python tests/character_psychic/run-tests.py` with `GODOT_BIN` and the existing offline `GAME76_HELPER_ROOT`. The runner treats every script/error line as failure. It records timings, mechanics/negative gates, separate-process results, a production campaign journey and separate labelled high-level development saves.

The Wave Three workflow runs the existing character foundation, frozen rules, save, opportunity, earned-XP, First Adventure and presentation suites plus Wave Two creature compatibility, new psychic mechanics and native exports on Windows/Linux. Exported QA runs with empty PATH and no source helper override. Production executable startup is separately verified.

Human review: extract both archive layers and run `road-has-gone-dark.exe`; start New Game, choose race/class, inspect Build > Specialisation and Powers. Compare Psion offence against control/support; Ardent mantles restrict choices; Lurk veils before ambushing with its blade. In combat choose a known power and augmentation, inspect points and legal targeting. Return home, earn advancement, exit and Resume. Existing campaigns must keep their original pins. No developer XP buttons are provided.

Screenshots and verified native download/checksum will be recorded in DELIVERY.md after successful verification; none is claimed at this checkpoint.
