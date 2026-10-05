# Prepared update — GAME-74

Status: implemented, ready for review; not accepted or merged.

Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/56
Base main: `238045b395ad9e693c71ac6b018442257fe0d6f3`.
Implementation and QA milestone: `64bd5e1f157568827a5f8766e4b411cdc4e52e7e`.

Player flow: intro → main menu → canonical world → state/optional province →
eight eligible small hometown suggestions → origin review → independent
GAME-7 save/reload → Party Creation Next. Back preserves valid choices,
upstream changes invalidate dependent selections, empty areas require another
region, and cancellation creates no partial saves. Saved-origin review cannot
duplicate the save. Existing skeletal adventurers remain invisible/unfinished.

GAME-8 boundary: a minimal read-only source-backed atlas preview and area
highlight, reusing existing MapRenderModel/MapRenderBaker. No atlas browser,
POI inspection, debug layout or research-stack migration. Canonical data,
accepted generators, application main scene and save schema remain unchanged.
GAME-7 eligibility now also excludes removed burgs.

Executed Godot 4.6.3 Linux: 3,968 source/save assertions and 17 real-render/input
checks, all passed, no Godot runtime errors. Existing GAME-7 and landmark
inspection smoke passed; canonical JSON 5/5 and both fixture validators passed.
Both canonical fixture hashes are unchanged. Isolated tests created and
reloaded two same-origin saves with different IDs, then removed test files.

Review evidence and Windows steps:
https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-74-new-game-origin-v1/docs/implementation/game74/README.md

Nine real Godot captures cover six successive flow screens, 640×360 and
2560×1440 output and the natural empty province Ris/Grorjujen in Atlas Showcase.
Native Windows/high-DPI acceptance still needs Mark's review. Continue remains
disabled pending save browsing and party setup. Packaging export filters are
documented; no export preset exists in the base. Character creation and all
gameplay remain out of scope. Existing PRs #51–#55 remain untouched/unmerged.

No authenticated Linear connector was available, so this update was prepared
for Mark/ChatGPT rather than claiming a ticket write or acceptance.
