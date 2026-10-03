# GAME-49 — source authority v1 (first bounded implementation slice)

## What this fixes

There are **three fundamentally different scales** in the current game project:

1. **Original Azgaar world geometry:** true *macro-source* coordinates for original burgs, original route polylines, and original polygon-vertex land/sea/lake outlines (the original vertex coordinates are exported through GAME-39's fingerprinted geography sidecar).
2. **Approximate macro observations:** source river `cells` joined through cell centres, coarse biome and height samples. These are **not exact river channels, barriers, village fields or topographic relief**.
3. **Future inferred walkable landscape:** Town Forge can illustrate forests and ridge marks independently, but those are not original Azgaar measurements. Existing GAME-47 correctly forbids its invented roads/water from becoming authoritative.

[GAME-48 draft PR #41](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/41) additionally shows why the currently visible **16-source-unit** local world window is not automatically **30 km**: a hypothetical Earth-sized world would render 30 km as only ~1–2 source canvas units, often containing fewer than four original Voronoi cell centres. The fantasy world's actual planetary radius is **unknown**.

## New opt-in SourceAuthority contract

`tools/regiongen/source-authority.mjs` creates a **separately versioned**, deterministic `source-authority:v1:<hash>` record for either the original v1 local-source context or the GAME-48 hypothetical reference-scale v2 context. It does **not** modify original world, regions, saves, site IDs, hidden knowledge or earlier source datasets.

All fields have precise provenance:

- `source_macro.towns`: **EXACT_ORIGINAL_MACRO_ANCHOR** — existing burg ID/name and untouched canonical world/local projected positions.
- `source_macro.routes`: **EXACT_ORIGINAL_MACRO_POLYLINE_NOT_FINE_ROAD** — the actual Azgaar source line, explicitly **not** a guaranteed walkable road, road class safety or ground path through a coastline.
- `source_macro.feature_polygons`: **EXACT_ORIGINAL_MACRO_VERTEX_POLYGON_NOT_FINE_SHORELINE** — actual source vertex boundaries, not footstep-level cliffs, harbour ramps or beaches.
- `derived_approximate.rivers`: **APPROXIMATE_CELL_CENTRE_CHAIN_NOT_CHANNEL**, with biome/height resolution also coarse.
- `inferred_fine_detail`: only matched Town Forge **decorative** ridge/forest marks may be passed in, flagged **INFERRED_DECORATION_ONLY** and with `source_authority:false`. Refuse wrong world/home/context, and any provider object that promotes invented roads or water.
- `unknown`: patrolled road safety, bridges/fords, exact meanders, actual docks/harbours, fine terrain barriers, cross-window seamlessness, physical-world radius where unspecified, and v1 save mapping. **Unknown is never automatically traversable**.

The new `source-authority:v1` IDs include the immutable original world SHA, real home ID and original context ID. They are independent of file names, UI labels and vendor seed display. There is no migration from `local-source:v1` or v1 GAME-40 site records; both existing v1 views and experimental v2 assumptions are kept independently intact.

### Sparse micro reference safety

When the optional GAME-48 reference window has fewer than **four source cell centres**, the contract explicitly reports `sparse_source_samples: true`, `local_footstep_water_mask: UNRESOLVED_AT_MACRO_SAMPLE_DENSITY` and `reliable_fine_road_geometry: false`. The engine must **not** interpolate an exact bridge, invent terrain barriers or claim local roads/passes from one or zero original source cells.

### This slice's tests and maps

`tests/regiongen/verify-source-authority.mjs` uses **12 original local windows** (three burgs × two seeded worlds × v1/v2 contexts). It asserts source town identity/coordinates, actual route group IDs, preserved feature provenance, stable IDs, consistent world SHA, and fails on forged source towns, unrelated worlds, invented provider water/roads or wrong assumptions. CI replays both Azgaar canonical worlds **byte-identically**, then generates **six explicit v2 reference maps** that show what source data actually covers at an *assumed*, **not canonical**, 30 km extent. An SVG/JSON Actions artifact preserves all six.

## Godot independent evidence viewer

The dedicated `scenes/debug/source_authority_preview.tscn` scene is an **opt-in QA tool**. It loads the six original reference-crop `authority-*.json` outputs. Use **F6** to run that exact scene, **1–6** to switch between the two original world seeds and coast/river/highland contexts, **F** to fit, and **S**, **A**, **I**, **U** to toggle original source, approximate, inferred and unknown layers. For now the **I (inferred)** layer correctly contains **no** generated fine terrain for the hypothetical 30 km reference, rather than inventing a road/shoreline. The unknown overlay explicitly identifies unsafe missing detail. Godot 4.7.2 CI tests all six scenes and toggles, without changing player saves or the existing regional views.

## Deliberately not yet complete

This is **GAME-49 first slice only**. There is still **no actual new 30 km walkable landscape**, no local-road/shore inference that has passed a realism/continuity gate, no source-aligned guaranteed adjacent-window topology, no **player-facing or playable** local-region UI and no site/save migration. The next integration will need a **fine terrain adapter with explicit inferred geometry**, constrained by true macro anchors, source dry-land and river uncertainties, and tests for coherent neighbouring regions; human full-size visual review is mandatory. Do not merge this data layer as a claim of finished playable regional geography.
