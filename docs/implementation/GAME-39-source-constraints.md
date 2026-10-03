# GAME-39 — first shared world-space constraint proof

This is a **data contract and geometry diagnostic**, not a working seamless Town Forge map. The real-world Azgaar canvas is one global coordinate frame: we use `map.width/height`, actual burg `x/y`, road `route.points[x,y,cell]`, and canonical river `river.cells` sequences mapped to cell centres. No independent cell-based randomness is permitted in these constraints.

## World space and identity

- **Version 1** transform divides the Azgaar map into globally anchored **64-source-map-unit squares**. A point belongs to tile `(floor(x/64), floor(y/64))`; tile origin is never centred on whichever settlement the player chose. Multiple burgs in a square share that source tile.
- Display geometry maps each tile to 1000×1000 internal preview units, preserving the source coordinate relationships. **64 Azgaar units are not 30 km.** No walking time or real scale follows from these numbers. This deliberately remains a clearly labelled calibration policy, not a fabricated world measurement.
- The source tile ID includes the immutable SHA-256 of the canonical Azgaar JSON and a projection version. It does **not replace** existing GAME-7 identities, GAME-21 generated terrains, nor GAME-40 site IDs/saves. When migrated, the existing legacy per-burg tile IDs require an explicit versioned mapping; do not reinterpret them silently.

## Authoritative versus approximated source geometry

- `route.points`: actual source-world `x/y` route points. These provide geometric polylines but **no evidence of safe/patrolled/protected status**.
- `river.cells`: Azgaar's cell chain; joining actual cell centres is a **derived approximate centreline**, not an exact rendered river course, confluence width or estuary. The model flags that approximation per segment and crossing.
- The original fixture includes `map.geography` feature summaries, but **not reconstructible vertex world coordinates**: `vertices` are graph indices without their position table. Lakes and seas cannot be faithfully classified/outlined from these summaries alone. The original Town Forge coastline and estuary shortcomings remain unsupported.
- Region boundaries and corners are clipped from the **same original source segments**, with crossing identity based on source line ID, global boundary coordinate and crossing world position. East/west and north/south views derive from the same data and should match, including multiple source crossings; tangential touches should not generate travel ports.
- Town Forge 1.2.4 currently generates independently seeded internal roads/rivers. Its landscape interiors have **not** been constrained to these source positions. No connected travel region, road protection, final coastline, inter-tile seamlessness or believable contextual POI placement is claimed.

## Review proof

Run in PowerShell from `C:\projects\road-has-gone-dark` on this branch:

```powershell
cd C:\projects\road-has-gone-dark
git fetch origin
git switch --create game-39-review origin/game-39-world-space-constraints-v1
node tests/regiongen/verify-source-projection.mjs
node tools/regiongen/preview-source-tiles.mjs --world tests/worldgen/fixtures/game-11-determinism.json --burg 1 --output tools/regiongen/.tmp/source-constraints-first.json
```

Expected test output begins with `PASS: GAME-39`. Open `tools/regiongen/.tmp/source-constraints-first.svg` in a browser. The pair of adjacent tiles should have visibly matching road/river segments at their shared border (brown actual Azgaar route geometry, blue cell-derived river approximation, red actual burg coordinates). There is no Godot scene in this slice: the debug evidence is JSON and SVG. The GitHub Actions workflow also generates this pair and a second-world comparison.

## Next integration stages

1. Audit and source-export the underlying packed vertex-world coordinates or approved derived geometry sidecar for **actual shoreline**/lake/ocean extents and rivers, with source version and immutable fixture checks.
2. Replace GAME-21's parent-cell-seeded conceptual `x/y` tile identity by a **separately versioned, shared source tile selector** that all burg entries use; do not rewrite old generated saves. Use this shared constraint layer to place source burg markers, paths and crossings.
3. Adapt Town Forge's local terrain **behind our own renderer/provider interface** to agreed source crossings (and document provider limitations). Only then anchor GAME-40 farms/inns/ruins in coherent relative positions and inspect visually.


## Second slice: true coastline and lake boundaries (3 October 2026)

The original `world.map.geography[*].vertices` records include indices into the pinned Azgaar `pack.vertices.p` table, which had been excluded from the canonical fixture. Unlike the former directional `water_side` hint, these positions reconstruct exact original coast and inland lake polygon boundaries. Rather than modifying stable fixtures or the upstream vendor, `generate-azgaar.mjs --geometry-output <path>` now exports a **separate versioned, SHA-256-fingerprinted source geometry sidecar** containing only the missing coordinate table. This is opt-in; ordinary world export output bytes and relief remain unchanged.

- Validation rejects a sidecar from the wrong canonical world, seed, provider version, upstream commit, map dimensions, corrupt vertices or invalid indexed features.
- `buildTileConstraints(world,x,y,sha,sidecar)` now clips the exact feature polygons and boundary segments into the **same global tile frame** used by Azgaar roads. It attaches `source_shoreline.polygons`, `segments` and canonical `crossings` and labels original island/continent boundaries separately from freshwater lake shores. `sideShorelineCrossings` checks E/W and N/S symmetry.
- The source diagnostic CLI can take `--geography <sidecar.json>` and renders land polygons over the sea background and lake polygons in blue; coastlines use original source geometry rather than Town Forge's illustrative coastline.
- The CI replays both pinned seeds to a temporary workspace, **compares regenerated canonical world bytes to existing immutable fixtures**, tests feature-sidecar fingerprints, and supplies both sidecar files and neighbouring-tile JSON/SVG diagrams as downloadable evidence.

### Visible shoreline seam acceptance

A pair of neighbouring tiles containing source land/lake outlines does **not** necessarily have a shoreline crossing at their own shared edge. The verification therefore also uses `--focus-shoreline`, which deterministically scans the **real indexed source polygon segments** and selects a non-tangent crossing of a global tile edge nearest the requested real burg. It never invents a crossing or moves a location. CI publishes `shoreline-focus-first/second.svg` and JSON with a `shoreline_focus` field identifying the source feature and original segment. Tests require a **non-empty matching source crossing** on both sides, as well as the general E/W, N/S consistency checks. These views are the explicit visual continuity proof, whereas the ordinary two-tile view illustrates settlement-road relationships.

### Explicit remaining limitations

The border lines/polygons are true **Azgaar source-feature geometry**, but rivers are still labelled **cell-chain approximations** because `river.cells` is not an exact meandered river polyline in the canonical records. Nothing here constrains Town Forge's internal shorelines, rivers, roads or ridge placement. Map scale remains uncalibrated; existing regions and saves are not migrated. The next slice is to incorporate these verified world constraints into the **rendering/provider adapter** while retaining Town Forge only as replaceable interior detail; then relocate GAME-40 locations based on true towns/routes and verified dry-land exclusion. Avoid hiding missing river mouths under decorative shoreline artwork.
