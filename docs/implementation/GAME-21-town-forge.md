# GAME-21 — Town Forge local-region experiment

## Source provenance

The source under vendor/town-forge/src and LICENSE is copied **without modification** from [Obsidian-TTRPG-Community/Town-Forge](https://github.com/Obsidian-TTRPG-Community/Town-Forge), **MIT**, upstream commit **4b25a37c14c80970d2b66f0c587468c7493855d3** (17 August 2026), package version **1.2.4**. Its upstream src tree was reconstructed from the compiled Obsidian plugin; parts of the TypeScript are effectively untyped. The pin is checked via canonical Git blob hashes in the GitHub Actions workflow.

Only the project-owned wrapper in tools/regiongen runs the original **generateFull(terrain, seed, {mode:"landscape"})**. The optional Obsidian UI, export integration, user-script hooks and rendered town-building mode are **not** used. The vendor is replaceable because no game feature reads its raw Scene data.

## Data boundary

The adapter accepts an **existing Azgaar source burg ID** and its **canonical world fixture** and validates provenance. The region seed is a deterministic combination of Azgaar seed and pinned version, source cell ID, a pair of local region tile coordinates, and local adapter generation version. **Changing a town display name does not change the terrain**. Different source cells or tiles generate different regions; a full world source hash is stored to detect incompatible source changes.

The selected Azgaar cell supplies an initial **terrain constraint**: verified shoreline flag (sea or lake), source river presence or steep mountain elevation; world biome influences forest density. Town Forge then generates native water polygons, forests, mountain ridges and **provisional** regional roads. The result is an **independent versioned JSON geometry model** (not an SVG-only texture). An SVG preview and a Godot 2D debug viewer read that model.

### Hard limits in this first spike

- The map is a **conceptual 30 km square** using Town Forge's own 1000-unit landscape domain, NOT a claimed calibrated projection of Azgaar's entire world. Scale calibration is explicitly marked provisional.
- Source river existence constrains **river terrain**, but specific river course and river-boundary orientation have not yet been matched to Azgaar macro route geometry. Water-facing cardinal direction now comes from adjacent source water cells, but this is only a coarse bearing, not a coastline projection. The source export does not distinguish sea from lake shores. A source river at a shoreline is retained in metadata and explicitly warned as not rendered; an invented river mouth would be misleading.
- Town Forge's current **roads are preview-only, NOT authoritative travel edges**. The adapter labels road connections as provisional. This prevents a procedural trail from falsely becoming a safe world-road in the player's game.
- Adjacent region tiles each have deterministic seeds but **tile-edge seamlessness is not yet proved**. Don't mark GAME-21 Done until a follow-up establishes actual shared edge connectors and route crossing contracts.
- No extra hamlets, guilds, dungeons, hidden sites, or local NPCs are invented from macro markers. Future layers attach to stable canonical world IDs and persistent playthrough deltas.
- The developer debug viewer is separate from the final New Game and atlas UI.

## Run locally in Windows PowerShell

After fetching this PR's branch into C:\projects\road-has-gone-dark and checking that local changes are preserved:

1. Open **PowerShell** and run:

       cd C:\projects\road-has-gone-dark
       npm ci --prefix vendor/azgaar --ignore-scripts --no-audit --no-fund
       node tests/regiongen/verify-region.mjs

   The Node command compiles the **pinned** Town Forge modules using the existing Azgaar build dependency tree and creates several deterministic JSON files and SVG previews under tools/regiongen/.tmp. Expect a line starting with PASS: GAME-21, plus seed hashes and region feature counts.

2. In **Godot 4**, open the local project from that same directory.
3. In the FileSystem panel, navigate to **scenes/debug/local_region_preview.tscn**.
4. Double-click that scene and press **F6** (Run Current Scene).
5. You should see forests, roads and, where generated, terrain/water features of one local area. Use **arrow keys** to pan, **mouse wheel** to zoom, **F** to fit the map. Press **1–6** to compare inland, shoreline, river, mountain, shoreline-with-source-river, and a second world. The fifth case explicitly warns that its source river mouth is not rendered. The top line shows the source cell and local region terrain; its label deliberately warns that regional routes are not game-authoritative.
6. For comparisons, open the generated SVG previews in **tools/regiongen/.tmp/first.svg**, **second-burg.svg** and **other-tile.svg**. The first two represent different hometown cells; the third is a different region tile at the first cell.

This is a generator proof, not yet a travelling character, dungeon or town interior.

## What should follow in GAME-21

Validate actual source route/macro-river geometry, calibrate a physical scale against Azgaar, force compatible shared road/river/coast edge connectors for adjacent tiles, and store/cache generated region IDs under the immutable GameWorld / per-playthrough delta separation proven by GAME-7. Then connect a preview selector in the player-facing map rather than shipping this QA-only debug view.

## GAME-38 audit and generation revision 2

The source adapter now validates aligned arrays, stable IDs, land height, source visibility and finite coordinates. It resolves neighbours by ID, even if cell arrays are reordered. Azgaar `terrain` is `pack.cells.t`, `heights` is `pack.cells.h` and `river` is `pack.cells.r` (see `tools/worldgen/headless-entry.ts`). Upstream `population-generator.ts` explicitly handles both lakes and oceans under `t === 1`; hence `cell_coast` remains a compatibility field meaning **shoreline**, with `shoreline_water_kind: unknown_lake_or_sea`.

Town Forge's unmodified `generateFull` accepts `seaSide` for its coastal style. We pass the cardinal bearing of the summed unit vectors to neighbouring water cells. Ambiguous/cancelling bearings remain unknown. This adds a real source constraint, but does not establish coastline position, shore shape, lake extent or river mouths. Its single terrain selector also suppresses mountains in some river/shoreline cases; output declares that limitation rather than silently claiming all source features were generated.

Generation revision **2** intentionally changes preview geometry and region IDs; regenerate temporary files. JSON schema remains 1 with additive fields. Region identity now includes the complete immutable source hash and conceptual km span to avoid collisions. Geometry seed excludes display names and full-file hash. Same-cell regions share geometry; `source.burg_id` records the requesting burg, not a separate regional map identity. A renamed/rewritten source file still has a distinct GameWorld fingerprint, matching GAME-7's existing policy.

Tests now generate both real worlds, actual shoreline/river/mountain/estuary examples, repeat determinism, signed tile coordinates, scale identity and malformed source rejection. They reject non-finite provider points and input/output path aliases. No fixture or vendor source is edited. Godot tests load every case and clear stale geometry after a failed load.

### Next bounded milestone: shared world-space constraints

1. Define **one** world-to-region coordinate transform and versioned map-unit/physical-scale policy. Cell or burg IDs select an area; they must not each create competing coordinate grids. `x/y` in this spike are independent variation seeds using the same parent cell, not verified adjacent geographical tiles.
2. Project authoritative Azgaar route and river polylines into that space, preserving source IDs and direction. Clip the same polylines against adjacent tile rectangles. Compute each boundary crossing once from the shared geometry; use a canonical boundary key and sorted source IDs. Do not generate random edge ports merely to make two tiles agree.
3. Establish shoreline geometry availability: the current canonical export includes cell centres/neighbours but not full feature records or polygon boundaries. Add a separately versioned derived sidecar or a reviewed export extension before promising lake/ocean classification or exact coastline continuity. Do not regenerate or silently alter accepted fixtures.
4. Test east/west and north/south crossings, corner hits, tangencies, multiple crossings, coast-plus-river mouths and two burgs selecting the same region. Reverse generation order and prove identical shared constraints. Roads do not imply protection; safe-road status needs gameplay data.
5. Only then constrain or adapt Town Forge interiors. `enabledEdges` supplies booleans, not exact connection positions; its river generator chooses random endpoints internally. Those APIs alone cannot guarantee seams. Keep provider source pinned and modifications in our adapter. If genuine constrained generation proves impractical, record that evidence before reconsidering providers.

A 30 km label currently stretches a 1000-unit landscape: it does not calibrate river width, road width or walking time. Do not derive travel ETAs from it. Cache verified immutable geometry by generation request; store discovery and changing local state separately per playthrough. For the first playable build, pre-generated JSON is the smallest packaging route; on-demand generation and a bundled runtime need a later explicit decision, not a Node installation requirement for players.

### Review judgement

Keep Town Forge as the replaceable **landscape prototype**. The layer boundaries and deterministic data model fit the agreed game; seamless world refinement is still unproved. Inspect the six examples before art approval. Forests are currently polygon masses and mountain `ridges` are actually upstream mountain footprint contours (`mountainsToRidges`), not illustrated peaks. Avoid spending a full art pass on these diagnostic shapes before world-space constraints are settled. PR #35 remains a draft; GAME-21 remains In Progress.
