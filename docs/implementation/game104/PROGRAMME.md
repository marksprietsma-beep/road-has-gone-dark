# Full character programme tracking

The entire GAME-88 character catalogue remains in scope. This branch delivers the first versioned foundation and a small usable original martial batch; it does not complete GAME-104 or the race/class/prestige programme.

GitHub programme: [#82](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/82), with actual child issues:

| Programme | GitHub child | Next capability |
| --- | --- | --- |
| GAME-36 | [#83](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/83) | Schema capabilities, exact pins and reviewed migrations |
| GAME-108 | [#84](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/84) | Inherited attributes, size, vision, resistance, body compatibility and acquired overlays |
| GAME-109 | [#85](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/85) | Distinct original base-class/archetype progressions |
| GAME-110 | [#86](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/86) | Earned prestige and hybrid progression |
| GAME-111 | [#87](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/87) | Actual skills/proficiencies, casting/powers and combat abilities |

Linear tools are unavailable in this session. These GitHub issues are mirrors for work tracking; Linear has **not** been updated. Reconciliation: keep GAME-104 and GAME-108/109/110/111 open; record this foundation checkpoint under GAME-36 and GAME-103 interface repairs. Do not mark the full programme complete.

## Exact continuation

Resume branch `feature/game-104-character-content-foundation` and draft PR81, stacked on draft PR80 `feature/game-103-character-builder`. Never restart or merge either draft without human review. Read AUDIT, coverage matrix, validation and delivery first. Preserve all released rules pack files and recorded content hashes; no silent migration of v1 or v2.

Next coherent delivery should implement typed inherited attribute/size/vision/resistance capability schema and equipment/class proficiency support, then an original ancestry/heritage cohort using those genuine consequences. This unlocks more of the catalogue without inventing unsupported dropdowns. Use GAME-108/#84 and GAME-111/#87 together; do not begin another world-content milestone.

For each remaining catalogue row, write a distinct original design and point `intended_implementation.production_id` at released content only after implementation. Retain researched/designed/implemented/mechanically_validated/playable statuses separately. Playable requires real creation, advancement, combat and persistence evidence. Original martial proof classes in this checkpoint do not erase the missing defining mechanics of Monk, Ranger, Barbarian or the other researched paths.

Recreate the matrix from the pinned research branch input with `python tools/character-content/coverage.py <catalogue.md> --check`. Source SHA in the JSON prevents drifting to a different transcription. Index headline discrepancies need a separate source reconciliation, not fabricated entries or a quiet scope reduction.

Regression and native build commands are in TESTING. Reuse the existing kernel, campaign owner, pinned helper and CI exports. No second rules engine or save writer.
