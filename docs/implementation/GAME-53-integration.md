# GAME-53 — integration of source-constrained POIs and inferred relief

This is an **integration preview**, not a merge of draft PRs into `main`.

## Lineage and source isolation
The new `game-53-integrated-terrain-preview` branch starts at GAME-51's latest tested source-authority/inferred illustration branch ([PR #44](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/44), stacked over GAME-49 PR #43, GAME-48 PR #41, GAME-46 PR #40, GAME-39 PR #39, GAME-21 PR #35). It imports the 15 exact Git blob versions of the **independently tested GAME-44 contextual-site work ([PR #42](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/42))**, in one identifiable tree/commit. The original source PR #42 remains untouched. Thus **both** branches' original immutable source canonical worlds, route and coastline provenance and player privacy contracts are present without rebasing into `main`, arbitrarily discarding existing v1 saves, or mixing unversioned APIs.

## What's displayed
`generate-contextual-region.mjs` now produces six GAME-44 regional previews with `local_sites_v2` plus a **separate** `inferred_fine_v1` illustration field, anchored to the identical source world SHA and source context. Inference is from Azgaar's coarse height/biome and globally seeded multiscale noise. `renderConstrainedRegion` accepts an **optional** field: when present it draws layered forests/relief masked behind the original Azgaar dry-land/lake polygons; source overland routes, original towns, approximate rivers and *discovered* game-owned POI glyphs draw on top. Older GAME-47 debug scenes with no inferred field still use Town Forge decorative trees/ridge symbols, preserving baseline regression.

The separate Godot F6 `scenes/debug/contextual_region_preview.tscn` reads the same local-region JSON, validates inferred SHA and context ID, and uses **V** to show/hide non-authoritative inferred terrain, **H** for developer-only hidden POI reveal and **A** for route conflict audit (off by default). `1–6` switches genuine world examples. Neither viewer writes to saved worlds.

## Critical limitations
The GAME-44 site regions are the **original 16 Azgaar-unit local source windows**, explicitly `UNCALIBRATED`, **not** GAME-48's separate hypothetical 30 km reference. The inferred field is globally deterministic but **visual only**; no verified travel traversability, road patrol coverage, bridges/fords, fine land/sea boundary, river mouth, regional physical size, pathfinding, village interiors, dungeons, threat spawning, or v1 GAME-40 saved-location migration results from it.

The GAME-51 hypothetical Earth-sized 30 km source/inferred proof remains **separate**, is not silently remapped over GAME-44's original site coordinates, and should not be mistaken for settled planetary radius lore.

## Acceptance gate
Both original CI suites remain active: `Verify local source neighbourhoods` checks the six GAME-44 maps, source dry-land and route classification, hidden-site privacy and Godot's actual F6 site/terrain toggle; `Verify source authority boundaries` checks six separate hypothetical v2 maps, source/inferred/unknown isolation and no false safe-road claims. Legacy Town Forge and GameWorld regressions also must pass. Review **all six SVGs at native 1000×1000**, checking source route/site alignment, believable forest/highland masses, absence of red QA warnings in normal view, no hidden labels, real sea and freshwater barriers, and different densities between environments. Visual approval does **not** turn these into playable regions.

No PR is to be merged into `main` until the stacked dependency review and site/save migration gates are agreed.
