# GAME-39 — Shared source-world spatial constraints (first bounded slice)

This slice supplies **authoritative source facts and consistent boundaries**, not fake seamless Town Forge interiors. It is deliberately stacked on GAME-21 / PR #35 and separate from GAME-40/42 presentation work. Existing canonical fixtures and pinned providers are unchanged.

## Source geometry audit (Azgaar 1.153.1 canonical export)

The existing canonical world JSON **already has useful coordinates**:

- `map.width`/`height` and `cells.points` carry Cartesian source coordinates. Source burgs have their own exact `x,y` positions. A burg's source cell centre is generally **not** its town centre.
- `routes[].points` are actual Azgaar route vertices `[x,y,cell_id]`. They can be projected directly; original route ID and road/trail/searoute group are preserved, but **no source field proves patrol protection or safe traversal**.
- `rivers[].cells` is an ordered source cell chain, not the drawn/surveyed river polyline. Projecting cell centres is a **source-derived approximation** and is marked as such; no exact rivers or river mouths are claimed.
- `map.geography` contains feature classifications, including oceans and freshwater lakes, plus *vertex indices*; the canonical export **does not contain the matching packed vertex coordinates**. Therefore it cannot yet support trustworthy shoreline polygons or seamless coast shapes. Exact ocean/lake per-neighbour classification is potentially available from the source cell/feature arrays, but must not be mistaken for complete coastal geometry. A future derived sidecar/export extension must include `pack.vertices.p` with stable validation, without modifying existing immutable fixtures.
- Coordinates are **Azgaar generator map units, not kilometres**. An assumed 30 km/Town Forge scene is currently uncalibrated; this slice never produces route distances or travel ETAs.

## Versioned coordinate policy

`tools/regiongen/world-space.mjs` introduces **absolute shared world tiles**, each **60 Azgaar Cartesian source units** wide, independently of entry burg or source cell. Tile `x,y` are absolute `floor(source_x/60), floor(source_y/60)` indices, **not** GAME-21's older independent, style-varying `--x/--y` parameters. Each tile renders to a local 1000-unit square, using one source -> renderer transform.

Stable constraint identity is `azgaar-rect:v1:<full source SHA-256>:side:60:<x>,<y>`. The policy version and unit-span are explicit, with separate uncalibrated physical-km status. A source burg selected by ID uses its actual `x,y`, is shown only in the tile containing those coordinates and carries the original Azgaar burg ID/name; two burgs in the same tile select the same tile identity.

Each real source route and river-cell chain is clipped as **source segments** against the source-world tile rectangle. A crossing receives a deterministic, shared `boundary_key` from source kind/ID/segment, axis, absolute grid boundary index and original crossing coordinate. The two adjacent tiles derive it independently but identically. Point-only contacts, tangencies and parallel boundary runs cannot create fake traversable exits. Corners can have two independently meaningful boundary axes. Output distinguishes source route vertices from coarse river-cell proxies, and declares `safety: unverified`.

No changes to `generate-region.mjs`, the Town Forge renderer, the GAME-40 site generation algorithm or world saves occur in this slice. **Do not mistake the new absolute grid for completed integration.** That is the next task after source constraints are accepted.

## Validation and visible proof

Run at project root in PowerShell after switching to this branch:

```powershell
cd C:\projects\road-has-gone-dark
git fetch origin
git switch -c game-39-review origin/game-39-source-spatial-constraints
node tests/regiongen/verify-world-space.mjs
```

The test uses both immutable Azgaar fixtures, then verifies deterministic identity, an actual source route crossing on both E/W and N/S tile pairs in each world, synthetic edge/corner/tangency/multiple crossings, two separate burgs in one tile, original ID/knowledge boundaries, source SHA retention and unmodified fixture bytes.

It outputs `tools/regiongen/.tmp/game-39-source-two-tile.svg` and `game-39-source-proof.json`, both uploaded in GitHub Actions. **The diagram is a diagnostic schematic**: roads from source Azgaar, coarse river proxies and source burg markers. It does not claim anything about local Town Forge forests, exact shores, estuaries, protected roads, walks or town interiors.

## Next implementation after acceptance

1. Add an immutable, versioned vertex-coordinate sidecar or export extension and test ocean/lake source feature matching; prove coast/river mouths or explicitly reject unsupported examples.
2. Wire GAME-21 terrain input and GAME-40 site positions to this absolute world tile, without changing site knowledge semantics or source settlement identity.
3. Design provider-constrained blending/edge generation. Unmodified Town Forge's booleans do not control exact edge intersection coordinates. If an adapter cannot force faithful seams, **do not silently draw made-up connections**; record provider limitation and revisit the adapter/provider choice.
4. Only after geography is coherent return to GAME-42 art evaluation and re-assess meaningful farms/inns/watchtowers related to actual routes and settlement geography.
