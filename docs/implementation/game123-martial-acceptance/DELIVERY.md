# Fighter / Barbarian native Windows delivery

The complete exported Windows release [40256408205](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40256408205) PASSED at source `e24d7a2ba920f167485ead1804327b7a59163a6d`. Later delivery commits change documentation, screenshots and the evidence-backed readiness record only; no tested game, rules, harness, exporter or workflow inputs change.

## Playable download

[Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40256408205/artifacts/12624458209) · [complete native evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40256408205/artifacts/12624458221). GitHub authentication may be required. Download and extract the outer artifact ZIP, then extract `fighter-barbarian-windows-x64.zip`. Keep the complete inner directory and run `road-has-gone-dark.exe`; no Godot, Node or separately installed artwork is required. Escape skips the intro. The inner playable ZIP SHA-256 is:

`2449b5160b23b0ff46af36df4430eb2fbe216c21a4a468f41f1853912e8bdbd0`

Independent archive audit verified7061 safe entries, CRC, AMD64 game and bundled Node, source-identical manifest/core,121 licence/credit files and no QA executable. The Windows workflow actually ran the native QA game with empty PATH/no installed-engine or source-helper overrides, separately started the production executable, and tested fresh and cold saved continuation. The host archive audit is static inspection, not Linux game validation.

## Implemented corrections

Three reproduced pinned29 mechanical groups were repaired in append-only30: Fighter Veteran/Pointblank bonuses now stack with their own training; Blade/Bow disciplines require the actual active weapon and apply only to matching attack profiles; Barbarian Resilient mastery15 grants usable +2 Fortitude instead of an unused pure-class save DC. Paid Rage combinations, finite resources, existing reactions and functioning late Whirlwind DC remain intact. Production tests also reproduced and repaired empty-query class/feat filtering, wrong-weapon self-action button availability, and an unrelated-option diagnostic dump. Locked-choice explanations and invalid-selection rejection remain.

Content is `trhgd-character-v30`,30.0.0, canonical hash `20aade16e0ee153c46d836245dfb0693b930ef7b66b18fe9590e1e50ab4dbb57`. Historical1–29 files and pins are unchanged. The50-career roster stays32 base /18 prestige; level cap20. No new ancestry, feat, spell, ability, equipment or creature records. Frozen combat, RNG and sole campaign writer are byte-identical to the baseline. Scoped weapon context is transient and restored after normal/natural/reaction resolution.

## Actual final native results

| Native phase | Warm checks | Independent cold checks | Failures |
|---|---:|---:|---:|
| Pinned29 defect reproduction |104|—|0|
| Current mechanics |1143|49|0|
| Extended martial combat |642|37|0|
| Production input |141|—|0|
| Ordinary earned campaign |623|8|0|
| Connected combat/resolution/home |34|82|0|
| All32 base tracks through20 |2598|65|0|
| Current upper casting |1634|97|0|
| Historical29 |1290|125|0|
| Historical18 |599|31|0|
| Legacy16 |818|4|0|
| Compatibility16 |1941|486|0|
| Frozen GAME32 |22181|—|0|
| Genuine Godot captures |36 /20 images|—|0|

These counts come from this final native run, not earlier source-only results. Each proof and its source binding, phase timings, distribution manifest, original renders and cold records are retained in the linked evidence. The ordinary campaign earns490XP through existing opportunities and deliberately advances three distinct builds to class8; ninth level remains unfunded. Connected actions spend real resources and cold-restart through resolution and eligible home recovery. Level20 examples are explicitly development fixtures.

The strict matching-source generator promotes only Fighter and Barbarian: **39 COMPLETE /11 PARTIAL /0 BLOCKED**. Earlier accepted37 retain their original evidence labels. This is bounded technical acceptance, not tabletop completeness or human balance approval.

## Limitations and continuation

Shared long combat action labels still clip and require scrolling, particularly at small resolutions. Native1280 requests rendered1280×719, recorded honestly. Existing humanoid LPC fallbacks remain; no new ancestry artwork. High20 fixtures did not earn level20 in ordinary play. Human Windows usability/balance acceptance remains separate. GitHub153 closes only after normal merge and actual post-main Windows success; parent101/GAME123 remains open. The authorised next pair is Monk/Paladin156, only after integration passes, on a fresh branch. No callable Linear connector exists; no direct Linear update is claimed.

[Review steps](TESTING.md) · [original screenshots](screenshots/README.md) · [next bounded work](NEXT-WAVE.md).
