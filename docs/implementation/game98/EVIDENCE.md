# GAME-98 visual and regression evidence

These images come from Godot 4.6.3 rendering the actual atlas layers, production expedition-map component and production expedition controller. Mesa llvmpipe under Xvfb supplied a real graphical renderer; headless test output was not turned into simulated screenshots. Contact sheets pair unchanged captures, resized for phone review.

## Six existing region contexts

Each contact sheet shows the source atlas around the actual hometown, the corresponding public local map, its selected destination, and the same map after locating its initially rumoured opportunity. The independent map-component review sheet deliberately identifies itself as a component. It does not imply that six separate full campaigns were manually played.

| Hometown | Source context | Phone contact sheet |
| --- | --- | --- |
| Aeveva, burg 22 | Temperate deciduous forest | [View](screenshots/region-00-contact-sheet.jpg) |
| Rixeiros, burg 164 | Wetland | [View](screenshots/region-01-contact-sheet.jpg) |
| Garmatkomlos, burg 341 | Savanna | [View](screenshots/region-02-contact-sheet.jpg) |
| Buena, burg 802 | Tundra | [View](screenshots/region-03-contact-sheet.jpg) |
| Nellasin, burg 49 | Grassland | [View](screenshots/region-04-contact-sheet.jpg) |
| Bilalarabar, burg 117 | Hot desert | [View](screenshots/region-05-contact-sheet.jpg) |

The contexts reuse GAME-99's executed sandbox corpus. All three canonical world SHA values and all six original content SHA values remain identical to the pinned values in [contexts.json](../../../tests/map_icons/contexts.json). No site recipes, positions, geography or extra landmarks were created for the screenshots. The public map initially has three located opportunities; the fourth has no map texture, tooltip or click target until discovered. Different underlying generated kinds may legitimately use the same approved generic encounter portrait; ruins retain their distinct ruined-structure artwork.

For every region, original PNGs include `normal` and `selected` at requested 640×360, 1280×720 and 2560×1440, plus `discovered`, atlas overview and focused atlas detail. [screenshots.json](evidence/screenshots.json) records the actual image dimensions and SHA-256 values. Some 1280-wide live-window captures have 719 rather than 720 image rows after Godot's viewport resize; these are preserved honestly, without padding or inventing a missing row. The 640×360 and 2560×1440 captures are exact, and all three requested presentation sizes are exercised by the contract tests.

## Actual resumed campaign and combat consequence

The full gameplay-controller captures below resume the genuine GAME-99 Linux recovery test's existing save, containing three persistent adventurers and previous victory/defeat records. This is an automated public test campaign, not the user's private save.

- [Existing campaign, 640×360](screenshots/existing-game99-completed-640x360.png).
- [Existing campaign, 1280-wide](screenshots/existing-game99-completed-1280x720.png).
- [Existing campaign, 2560×1440](screenshots/existing-game99-completed-2560x1440.png).
- [New victory and journey XP](screenshots/existing-game99-new-victory.png).
- [Returned local map with retained identity and completion tick](screenshots/existing-game99-post-victory-local-map.png).
- [Neutral missing-resource feedback](screenshots/missing-resource-neutral-placeholder.png).

The test compares original save bytes immediately after resume, original party identities and immutable site base SHA. It selects the remaining opportunity through the production controller, verifies selection does not write campaign state, travels, plays the existing tactical encounter to victory, records 10 journey XP per companion, returns, rests and reloads. It verifies the selected marker, correct tooltip, saved completion overlay and idempotent rewards.

## Automated contract coverage

[Linux graphical proof](evidence/linux-render-proof.json): **606 checks, zero failures**, including 54 captures from the review flow. Six additional focused atlas-detail captures bring the evidence to 60 original Godot PNGs. The headless source/native runs use the same contracts without screenshot or graphical-corner assertions, so their check counts are smaller. Counts measure assertions, not distinct worlds or battles.

Coverage includes original approved SVG decoding, every settlement role, all Azgaar marker types, shared Node/Godot semantics, truthful fallback roles, unknown/rumoured exclusion, source versus generated provenance, fixed geographic centres, 32-logical-pixel targets, nearest-centre routing in crowded areas, real mouse selection, transparent corners, stable control instances on selection, responsive layouts, missing-resource feedback, byte-preserving resume and saved victory/reload. [The source log](evidence/linux-render.log) and [landmark inspection log](evidence/landmark-inspection.log) preserve the actual output.

The existing GAME-83/GAME-84 full graphical mouse/keyboard journey also passed **476 checks, zero failures**, at all three requested sizes: [log](evidence/legacy-ui-input.log). Two existing preset worlds supplied test-owned campaigns, prepared with 89 passing lifecycle checks. The older driver assumed that every child was a site and omitted the new hometown control. Its updated assertions compare the exact public site IDs plus the known hometown, and use IDs rather than visual draw order for mouse targets. No visibility assertions were removed. The journey includes party-ready handoff, rumour/scout/travel, choices/consequences, Tab/arrow/Enter navigation, menu resume, saved outcomes, correct marker centres and tooltips, scroll/focus behaviour and footer/readability checks.

Native package verification runs the exported diagnostic executable with an empty `PATH` and no `GAME76_HELPER_ROOT`, against the bundled helper; it also launches the actual production executable and removes the diagnostic executable from the deliverable. Linux and Windows proofs, timings, workflow results and archive integrity details accompany the final delivery document.

The first native run caught a real source-only loading assumption: raw SVG paths are remapped inside the exported PCK. The provider now follows Godot's imported resources when raw files are unavailable. A previous static taxonomy check also assumed an obsolete local alias table; it now validates the shared mapping while retaining all 36 upstream type and source/licence checks. These failures were corrected rather than hidden by weakening the exported-game verification.
