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

## Independent-review amendments — PR #56

Reviewed the latest independent GitHub review comment (5990365042) and this
prepared update before changes. Live Linear access remains unavailable.

Fixed post-save validation: only a successful write AND immediate validated
reload permit Origin Established. Failed reload stays on confirmation without
a saved-state claim and discards only that newly written slot. If cleanup fails,
its exact path remains owned and another write or Back is blocked until cleanup
completes. GAME-7 validation and save format are unchanged.

Added deliberate on-disk corruption regressions: 26 checks pass for repeated
validation failures, no handoff/false claims, zero leftover failed slots, one
valid retry, Back/cancel, cleanup failure blocking and cleanup recovery. The
source/save suite now has 3,973 passing checks; actual input/render flow has 17
passing checks. GAME-7 persistence, landmark-inspection and canonical validation
were rerun successfully. Logs and persistence proof are refreshed.

Primary UI now uses World I / World II and source-backed settlement descriptors,
with concise Walls/Port notes. Seeds, fixture keys and immutable identities are
unchanged internally. Layout/style remain approved and unchanged. Only six
existing screenshots with visibly changed text were updated; menu, region and
empty-area images were preserved. Native Windows review remains pending.

Continue remains disabled. No gameplay, character creation, generation, GAME-8
expansion or protected PR changes. PR #56 remains draft for review, not accepted.
