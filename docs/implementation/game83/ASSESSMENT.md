# GAME-83 engineering and interaction assessment

Verified base: GAME-84 `3541e0bb2cc72ee147c3589e3a354b3b670d85e5`, draft PR #66; all existing PR checks passed. Work branches from that exact head. Existing untracked `research/` is unrelated and preserved.

## Confirmed causes

The application stretches a fixed 640×360 canvas at every window size. A 14-unit body font becomes 56 physical pixels at 2560×1440; changing font sizes alone cannot fix desktop density. Origin, party and expedition screens independently duplicate themes, StyleBoxFlat construction, labels and footer buttons. Every action has similar weight. Origin splits long prose across small fixed scroll areas, party uses a fixed 370-unit description width, and expedition repeats save-validation wording and an ambiguous ring legend. Its public map raster includes the accepted renderer's oversized settlement decorations. Outcome text does not clearly separate the completed objective from newly learned information.

## Refined implementation

Use one small UI utility/component set with a shared theme, typography, selectable rows, badges, section/detail treatment and footer actions. Keep the existing screen controllers and public variables used by input tests. Make player-screen canvas size responsive to actual window size, with a 640×360 minimum and a bounded desktop reading scale; retain the existing intro configuration. Lists/maps gain room at larger sizes while controls grow more slowly. Keep errors visible, use subdued metadata and concise save feedback, preserve keyboard focus and scrolling to focused controls.

For the expedition, filter decorative settlement SVG elements only when displaying the already verified packet. Do not change packet bytes, hashes, site generation, saves, knowledge or accepted regional algorithms. Replace rings and numbered rectangles with compact semantic symbols, a combined hometown/party state and explicit selection. Known-site text access remains available. Clarify existing goals and recorded results using the public projection and campaign outcome records only.

## Verification and delivery

Capture the unmodified baseline and matching after states with actual Godot rendering. Review main menu, origin, party, hometown, lead, map, site, result and return at 640×360, 1280×720 and 2560×1440. Exercise mouse, Tab/Shift+Tab/arrows/Enter/Escape, focus visibility, clipping, marker hit targets and hidden-information boundaries. Compare exact persistence outputs for unchanged operations, including existing GAME-84 restart/failure tests and GAME-74/75/76/79/80/81 regressions. Windows/Linux CI must build and execute complete distributions with the matching helper. Publish a new draft PR against GAME-84 with evidence and limitations.

No combat, facilities, inventory, economy, new content generation, save migration or gameplay mechanics are included. GAME-85 is only accommodated by composable hub sections. Authenticated Linear tools are unavailable; a prepared update will be committed.
