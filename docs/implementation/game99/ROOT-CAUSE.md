# GAME-99 — original Azgaar geometry and campaign recovery

Tracks [GitHub #76](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/76). Base: current verified `main` 1263f146ad5422945b355869ab2d977f14e0a4ef, whose production Linux/Windows workflows passed. This branch is a repair, not another consolidation or gameplay milestone.

## Reproduced defect

The unmodified pinned Azgaar 1.153.1 / cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6 pipeline regenerates `game96-sandbox-review-v2` with canonical SHA **c9eb47dacfe4560df8cdd4bb128ab578ff2997e288c79665fb2cf9ab5791cbe1**. The original sidecar exporter fails at vertex **9109**, coordinate **[722.0000000000003,800.4226306386807]**, on a **1280×800** map.

This is a finite, legitimate Voronoi circumcentre, 0.4226306386807 source units below the visible canvas. It is referenced by **real cell 5734**, not a coastline/lake feature. Packed graph has 5736 real cells. Its Delaunay points are IDs **5807,5809,5734**, positions **[712,810],[732,810],[727.25,787.61]**: the first two are boundary pseudo-points. Twice the oriented triangle area is **−447.7999999999993**; squared distances from the centre to the three points are **191.72600388314365,191.72600388313,191.7260038832566** (floating point agreement). Neighbor vertices are **−1,8970,8617**; −1 is the outer hull sentinel, not a missing polygon reference. Neighboring circumcentres are [734.60614970604,797.7482576550343] and [712.2053614772229,793.7514275358516]. The real cell ring and shared borders pass source geometry checks.

`grid-generator.ts` intentionally places boundary pseudo-points outside the rectangle. `voronoi.ts` computes genuine circumcentres from Delaunay triangles and `pack-generator.ts` retains the resulting original graph. Our sidecar writer incorrectly required **every** original graph vertex to be inside the drawing rectangle; its reader repeated that assumption. Generation succeeded; sidecar export failed before local projection or sandbox generation.

The user-reported **11702** is a separate real Windows failure of this same check. Its seed/source data were not supplied. We do **not** claim that exact world or coordinate was reproduced; it could also represent malformed geometry. The known-source reproduction establishes the root cause for 9109 and repairs the bounds contract generally while preserving corruption rejection.

## Narrow repair

Keep sidecar **schema v1**, coordinates, array order, vertex IDs, rings, source seed, provider pins and exact canonical bytes. Accept finite two-dimensional source coordinates without applying canvas bounds. Both writer and reader call the same validator. It checks positive finite map dimensions; all vertex coordinates; missing/duplicate polygon references; nondegenerate finite polygon area; proper self-intersection; complete cell table when present; and cell rings surrounding original source centres. Feature-only original v1 sidecars remain supported. No vertices are clamped, discarded, replaced or reindexed. No Azgaar source or canonical serialization changes.

`source-projection.mjs` and `local-source-context.mjs` already clip display polygons/segments in the shared global coordinate frame. Those algorithms and their world/local transforms remain unchanged. The original cell polygon remains exact; its local display window stays inside the canvas. Genuine shared coastline/lake/cell edges therefore retain their original continuity.

## Existing campaigns

Failed exports previously left a canonical replay but no geography sidecar. The existing campaign writer preserved the save. `tools/expedition/geography-cache.mjs` now reconstructs only the missing derived cache in private `.geography-repair-v1-*` staging, checks **exact canonical replay SHA**, validates the sidecar, stages its checksum and publishes the sidecar last. Interruption before publication leaves a missing cache and can be retried. Successful sidecars are reused byte-for-byte. Corrupt/unverified published caches continue to fail closed; they are never silently repaired or replaced. Unmatched canonical replay publishes nothing.

The helper-integrity manifest is refreshed for these source files. Its runtime hash is an executable integrity pin, not a campaign content revision: local recipes, content IDs, packet bytes, source generation versions and combat authority are unchanged. No new save writer, save migration, world-library identity migration or profile reset is introduced.

Tests use an archived original production source and its original compatible helper to create a genuinely blocked campaign, then independent repaired-source processes to resume it, fight, return and reload. Another valid original campaign pauses midbattle before the same source-version handoff. The native Windows package additionally drives the exported production controllers against the untouched old blocked save with no source helper override and empty PATH.

## Review status

Publication remains a draft. Completed evidence and repaired Windows download/checksum will be recorded in DELIVERY.md after verification. The actual user profile was not available; recovery is verified against generated original-version profiles, not claimed against the user's private data.
