# GAME-56: pinned Expedition Demo

Run the project normally (F5 in Godot), pass the intro, then choose **Expedition Demo** in the main menu. The Windows package opens the same flow by double-clicking `RoadHasGoneDark.exe`; keep its `.pck` beside it. No Node generator, Codex, or pre-generated `.tmp` maps are needed.

The demo starts three travellers at **Kindum**, in one bundled 16-source-unit local region from the immutable `atlas-showcase` fixture. It uses the same Game-icons family as the world map. This is a session-only exploration prototype: choosing the demo again starts fresh. **New Game** remains the separate placeholder, and **Continue** remains disabled.

## What to test

1. Launch through the intro and main menu. Check that the map, four known non-home site markers, party status and journal are visible and readable.
2. Click a known site, then press **T** to journey there. Check that the target/location, supplies, hours and journal update sensibly.
3. Press **C** to investigate cautiously. Expect one clue, a supply cost, time passing, and the site marked visited. Investigating it again should give a clear refusal rather than repeat rewards.
4. Try **S** to scout. It consumes supplies/time and can reveal nearby hidden or rumoured sites; their names/markers should stay hidden until discovered.
5. Try **B** at another unvisited site for a bolder investigation: more clues and more danger. Press **R** to return to Kindum and resupply; discovery/visited state should survive this return during the same session.
6. Press **X** to show/hide the hex grid; **F** fits the map, arrows pan and the mouse wheel zooms. Check shared icon consistency and whether the local scale/density feels useful.
7. Press **Esc** to return to the menu. Re-enter the demo and check that its session resets. Debug reveal/audit/occupant/route-timing keys and 1–6 sample switching must not change the playable demo.

Journeys are abstract story turns, not animated walking. Their current hours are prototype balance values. Hexes measure source-map distance; kilometres and calibrated walking speeds are still undecided. The source-water filter excludes obvious coast/lake crossings, but neither scenery nor source roads certify walkability, safe patrols or verified bridges. Bandit/monster sprites remain developer mockups, outside this demo.

## Where this sits in the game flow

**Intro → main menu → Expedition Demo → Kindum → select a known site → journey → scout/investigate → return and resupply → repeat → Esc back to menu.**

This validates the local exploration loop and map readability. World/seed selection, choosing a starting region, character creation, persistent campaign saves, tactical combat, inventory and full town/dungeon exploration are later roadmap work. This demo does not claim those systems are complete.

## Packaging and checks

`tools/regiongen/package-expedition-demo.mjs` deterministically packages the pinned Kindum example after regenerating the contextual examples. It strips developer occupant/route-preview layers, retains source geography, scenery, shared icons and geometric hexes, and records the region SHA plus source-world/context/burg identity in `assets/demo/manifest.json`.

`verify-expedition-demo.mjs` checks the bundled data against the immutable source fixture. `smoke-expedition-demo.gd` exercises the menu button, bundled load, actual known-marker draw hooks, playable journey/investigation/return, privacy, disabled sample/debug controls, and Escape back to menu. It also runs against the exported PCK. The export workflow works from a fresh checkout without generated examples and captures an actual viewport before uploading the Windows package.

Local validation: source and packed-resource smoke checks passed; Windows export succeeded using Godot 4.7.2. The Windows executable has not been run on Windows here. Fresh desktop screenshot review and the draft PR dependency consolidation remain acceptance gates before GAME-56 is marked complete/released.
