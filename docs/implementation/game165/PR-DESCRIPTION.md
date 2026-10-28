After Summon Sentinel spent the Druid's movement and action, End turn remained enabled but was pushed outside the viewport by the expanding footer layout. Withdraw stayed visible. Keep End/Return first at the left edge, put the spacer last, and distinguish ending a spent turn from deliberately accepting defeat.

Only one production UI file changes. Combat commands, gating, presentation timing, RNG, XP, save ownership and immutable v1–v33 packs remain unchanged. Strict historical guards verify the exact footer change and one diagnostic export scene; every other production source and the 45 COMPLETE / 5 PARTIAL readiness matrix stay frozen.

Validation:

- Original Windows reproduction: 29 checks confirm enabled-but-offscreen End; the existing engine advances normally.
- [Native Windows smoke](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042) passed at `89553b0de704ea2073a0eb5b30a25e024fe654c3`: 35 control, 121 campaign, 10 independent cold, 1,941 historical, 486 historical cold and 22,181 frozen checks; zero failures. Real mouse input uses the original scene/service/thread/writer. No duplicate full-class release.
- Summon → End at zero budget → Sentinel movement/end → Knight/enemies/party, Wolf coexistence, exact expiry, cold continuation and deliberate-only retreat pass. Windows 640/1280, actual CI fullscreen 1024×768 and a separate 2560 window probe; original PNGs retain actual render dimensions.
- [Self-contained Windows x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40610003042/artifacts/12782383693); playable ZIP SHA-256 `a84ec95a1e44d4fcc62a25e0bc0d3928ce10121bae39add2f74e97e7ef221ec1`. Independent archive/source/AMD64/dependency/licence audit passes. [Delivery and retest steps](docs/implementation/game165/DELIVERY.md).

Later commits contain only documentation/evidence and have no runtime/test/export difference from the tested source. No private save was accessible; its seed/world is not claimed, and an already-recorded defeat is not rewritten. Existing label clipping and humanoid creature-art fallback remain documented. No Linux Godot validation.

Tracks #165 and parent #101 / GAME-123. Keep the bug open until actual post-main Windows checks pass; keep the overall milestone open. No next class cohort.
