# GAME-46 — authentic Azgaar neighbourhood context (first slice)

## Why this exists

GAME-39 [draft PR #39](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/39) establishes Azgaar's globally consistent macro tiles, real burg positions, real source road/sea-route points and exact original lake/coast polygons recovered in a fingerprinted **optional geography sidecar**. Those macro tiles are **64 units of the original Azgaar canvas**, not a defensible physical 30 km. GAME-21 Town Forge currently generates independent 1000×1000 conceptual landscapes, incorrectly described as geographically continuous if overlaid directly. This separate module **does not silently replace or reinterpret** those existing region IDs and saves.

`tools/regiongen/local-source-context.mjs` now supports a second, explicit coordinate system: a **16-Azgaar-source-unit neighbourhood window** centred where possible on a real, visible burg. This span is *only a diagnostic choice*, and deliberately **not converted to kilometres**. Its 1000-unit local display projection is mathematical, not a physical map scale. Two different source burg IDs can select overlapping windows while retaining their distinct home contexts; global macro source tile identity remains unchanged.

## Provenance

The local source context contains **only**:
- the real home burg `i`/`x`/`y`/cell, other real visible burgs falling inside the window;
- original `route.points`, clipped as inland roads, trails, sea lanes or unclassified source routes — never marked safe, protected or connected by invented bridges;
- clearly **approximate** river polylines derived from `river.cells` cell centres; no fabricated mouth or authentic meandering channel;
- original land and freshwater-lake feature polygons clipped from the independently validated GAME-39 `--geometry-output` vertex sidecar, with source features and IDs preserved.

The result uses a separate `local-source:v1:<hash>` identity. The source GameWorld JSON, old Town Forge region IDs, GAME-40 POIs, player knowledge/discovery and saves remain untouched. There are **zero generated local sites**. This is a constraint/input model for future Town Forge integration, not new gameplay or completed map artwork.

## Evidence and acceptance

CI replays two Azgaar seeds and compares canonical bytes to existing world fixtures, verifies a synthetic context and **80 real burg neighbourhoods**, then generates six full-scale SVG and JSON pairs for actual coastal, river and highland source burgs. All geometry comes from those worlds. `tools/regiongen/preview-local-context.mjs` is for review only, not a Godot gameplay map.

The acceptance gate is **not** satisfied simply by passing Node/Godot checks. Inspect all six SVGs to confirm roads actually relate to settlements, dry-land placement, shoreline shapes and variety. The output may still be sparse because there are intentionally no invented buildings, forests, local paths or gameplay features yet.

## Next bounded integration work

1. Determine defensible geographic calibration/zoom and design a policy distinguishing known source coastline/roads from inferred/local terrain. Do not call a 16-unit source window 30 km.
2. Refactor the Town Forge adapter to *receive this context* and generate only replaceable interior detail. Draw original shoreline/route/real town constraints above independent decorations. Verify it doesn't overwrite real source geography or clip trails into seawater.
3. Site placement: anchor local inns/farms/fortifications contextually against source roads, terrain and a validated land mask. Handle lakes, coast/rivers and unseen locations without leaking hidden data. Provide a versioned save migration, rather than silently replacing region/site IDs.
4. Review visual proof at native resolution ourselves before asking Mark to accept; only then build the interactive Godot preview and test it.

### PowerShell for development verification

```powershell
cd C:\projects\road-has-gone-dark
git fetch origin
git switch --create game-46-review origin/game-46-local-world-context-v1
npm ci --prefix vendor/azgaar --ignore-scripts --no-audit --no-fund
node tools/worldgen/generate-azgaar.mjs --seed game-11-determinism --output tools/regiongen/.tmp/local-replayed-first.json --geometry-output tools/regiongen/.tmp/geography-game-11-determinism.json
node tools/worldgen/generate-azgaar.mjs --seed atlas-showcase-06 --output tools/regiongen/.tmp/local-replayed-second.json --geometry-output tools/regiongen/.tmp/geography-atlas-showcase.json
node tests/regiongen/verify-local-context.mjs
node tools/regiongen/generate-local-examples.mjs
```

The GitHub Actions workflow performs stricter canonical byte comparisons and publishes all six images. Manual local testing is **not requested** until the combined interactive layer exists.
