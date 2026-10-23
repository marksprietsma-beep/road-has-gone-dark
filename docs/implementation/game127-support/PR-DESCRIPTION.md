## Problem and resulting behaviour

Cognition Adept's adjacent melee strikes inherited ancestry weapon reach: a valid Ogre could strike from two tiles. Immutable v26 requires equipped melee and exact adjacency for all five strikes while preserving psychic damage followed by a separate weapon roll. The shared caption now respects adjacent-only descriptors, including historical Lurk.

Fresh campaigns default to v26. Historical v1–v25 bytes, pins and battle semantics remain unchanged. No roster growth, combat-engine replacement, save migration or world changes.

## Verified acceptance

Psychic Warrior, Divine Mind and Cognition Adept passed bounded choices, progression, tactical costs/effects, aura interruptions, multiclass resources and optional earned prestige contracts. [Full native Windows release 39882645495](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39882645495) succeeded at `e65d098a68858ef9247a7644a94b2485f671a323`: 1,159 mechanics / 135 cold; 108 actual controls; 620 earned / 8 cold; 40 connected / 76 cold; 2,598 all-base audit / 65 cold; current/historical suites; 22,181 frozen oracle assertions; 24 native Godot PNGs. Every phase zero failures. Windows only.

Three genuinely earned 490-XP / total-level-8 careers include explicit Psychic Warrior 6 / Cognition Adept 2 advancement. High-level base-20/prestige-5 fixtures are labelled development-only. Historical and exact restart/RNG invariants remain intact. Final delivery/readiness/evidence changes preserve exact runtime, test and packaging source equivalence to the release commit; no duplicate full release.

[Windows x64 download](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39882645495/artifacts/12473865536). Extract both ZIP layers, keep all files together, launch `road-has-gone-dark.exe`; no installed Godot/Node. Inner ZIP SHA-256: `3e2a7b76d3e503cebc0014087c1f4a006d76b2e49febc0d0038d9f371f400c18`.

[Delivery](docs/implementation/game127-support/DELIVERY.md), [test instructions](docs/implementation/game127-support/TESTING.md), [screenshots](docs/implementation/game127-support/screenshots/README.md), [raw evidence](docs/implementation/game127-support/evidence/native-proof.json), [archive audit](docs/implementation/game127-support/evidence/archive-audit.json).

## Remaining scope

Evidence-backed readiness **29 COMPLETE / 21 PARTIAL / 0 BLOCKED** across 50 existing careers. No added class, ancestry, feat or power. Bounded technical contracts do not replace human balance/usability acceptance. Shared psychic pool, natural-form suppression, fallback sprites and scroll-dependent small panels remain documented. GAME-92, GAME-89 and GAME-140 stay separate.

Tracks GAME-127 / GAME-123 / [milestone #101](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/101), which stays OPEN / In Progress. Direct Linear updates unavailable; GitHub and committed records carry the handoff. Next recommended Metamind/Pyrokineticist cohort is not implemented here. Stop after verified publication.
