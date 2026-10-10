# GAME-83 production interface

Base: GAME-84 `3541e0bb2cc72ee147c3589e3a354b3b670d85e5` / PR #66. Branch: `feature/game-83-production-ui-system-refactor`. The draft PR targets `feature/game-84-first-production-expedition-v0`.

## What changed

Origin selection, party creation, the hometown and expeditions now share typography, colours, focus treatment, list styling, actions and badges. Body text uses parchment, gold identifies headings and primary actions, and metadata has lower emphasis. The main menu and settings use the same theme. Party rows show all three names, ancestries and roles. Ready parties open on readable backgrounds rather than disabled editing fields. Existing origin profiles, factual context and public lore remain available.

The fixed 640×360 canvas previously multiplied every control by four at 2560×1440. Player screens now use additional logical layout space: approximately 640×360, 905×509 and 1280×720 at the three requested sizes. Body type remains 14 logical units; its physical size grows by roughly 1×, 1.41× and 2×. Political lists reveal more entries; the hometown shortlist stays compact so its longer lore has room. The party reading column has a maximum width. The intro retains the existing project configuration.

Hometown leads use compact title/status rows. The hub composes named sections for local accounts and recent events; a future service screen can add sections without replacing the frame. Site/result titles explain the current phase. Results show investigation status and the existing recorded consequence under “What changed.” The save indicator is subordinate; failures retain visible feedback. Footer navigation remains outside the detail scroll.

## Map composition and information boundaries

The accepted renderer emits each decorative settlement asset inside a 26-unit nested SVG viewport around 512-unit icon paths. In the baseline Godot render, those paths become the oversized house. `LocalMapArt` retains the source settlement circle and removes the nested decoration while displaying the verified SVG. It also removes unsupported SVG text and its empty caption backplates. Terrain, rivers, road strokes, cell boundaries, coordinates and the cached packet remain unchanged.

Known sites use compact diamond symbols, selection uses a gold outline, and a small party indicator marks the current site. At the hometown, one house/pennant symbol represents the combined position. The footer names the party's location directly. Marker tooltips retain public names and knowledge state; undiscovered sites are still excluded by the original public projection. Keyboard targets and local-account rows provide alternative selection routes.

## Components and boundaries

`scripts/ui/components/game_ui.gd` owns theme construction, labels, actions, sections, badges and reading width; `choice_row.gd` is a single focusable row with separate status. `responsive_canvas.gd` controls player-screen scaling. `site_marker.gd` draws the compact selectable symbol; `local_map_art.gd` adapts only the displayed artwork. Existing screen controllers retain their state and service APIs.

World/origin generation, party and expedition services, save validation/schema, knowledge rules, lead semantics, generated site content, world deltas and consequences are unchanged. No gameplay systems or facilities are introduced. The only packaging change allows the existing native expedition verifier to name its GAME-83 archive/evidence directory; its lifecycle assertions remain intact.

## Reproduce

Use Node 24.19.0, Godot 4.6.3 and the branch-compatible bundled helper prepared by `tests/world_library/prepare-ci.py`.

```sh
python tests/ui_system/run-tests.py --visual --regressions
# Linux: run within Xvfb or an existing desktop display.
# Windows source CI omits --visual; the native distribution proof still runs.
```

The runner executes original GAME-84 and GAME-74/75/76/79/80/81 regression entry points, then captures the production UI. Baseline screenshots were taken before applying the shared theme/layout changes. Screenshot comparison, executed results and native build links accompany the final evidence.

## Review package

- [Before/after sheets and all three window sizes](SCREENSHOTS.md)
- [Per-screen UX review and compromises](UX-REVIEW.md)
- [Reproduced Back regression and correction](BACK-NAVIGATION.md)
- [Actual executed tests](TEST-RESULTS.md)
- [CI and complete Windows build](CI-EVIDENCE.md)
- [Source boundaries, complete save comparison and screenshot hashes](review-proof.json)

The comparison run used copies of the same initial campaigns on GAME-84 and GAME-83. All 14 complete saved records match; one was exercised by the three-resolution capture journey and the others remained untouched. No fields were normalized or excluded. The separate full regression suite exercises the broader campaign/world matrix. `verify-review.py` reproduces this comparison when supplied the three owned test roots.

## Windows review

Extract the complete Windows artifact and its inner archive. Keep the matching `worldgen-helper` directory beside the executable. Launch, skip the intro, and proceed through world/state/region/hometown confirmation and party creation. Check all three roster entries, ancestry/role selectors and backgrounds with mouse and Tab/Shift+Tab/arrows/Enter. Mark the party ready and enter the hometown.

Select a known lead and then a rumour. Accept the rumour, depart, scout and travel. Check that a hidden location appears only after scouting, that the selected/party markers are distinguishable, and that costs/actions remain the GAME-84 values. Make a choice, read the recorded consequence, return home, quit the executable and Continue. Repeat at 640×360, 1280×720 and 2560×1440. Check the ordinary Windows scaling setting used on your laptop as well as window resizing.

## Review limits

The refactor communicates the existing expedition consequences; it cannot make the current three lead-goal forms or repeated content broader without changing the authorised scope. At 640×360 long origin profiles and recent events still scroll, while primary navigation stays visible. Dense map locations may require keyboard or text selection. Automated rendering measures layout and input, but the subjective “primary action within two seconds” criterion and Windows laptop display comfort need human review.
