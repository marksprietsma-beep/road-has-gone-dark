# GAME-21 — Town Forge local-region experiment

## Source provenance

The source under vendor/town-forge/src and LICENSE is copied **without modification** from [Obsidian-TTRPG-Community/Town-Forge](https://github.com/Obsidian-TTRPG-Community/Town-Forge), **MIT**, upstream commit **4b25a37c14c80970d2b66f0c587468c7493855d3** (17 August 2026), package version **1.2.4**. Its upstream src tree was reconstructed from the compiled Obsidian plugin; parts of the TypeScript are effectively untyped. The pin is checked via canonical Git blob hashes in the GitHub Actions workflow.

Only the project-owned wrapper in tools/regiongen runs the original **generateFull(terrain, seed, {mode:"landscape"})**. The optional Obsidian UI, export integration, user-script hooks and rendered town-building mode are **not** used. The vendor is replaceable because no game feature reads its raw Scene data.

## Data boundary

The adapter accepts an **existing Azgaar source burg ID** and its **canonical world fixture** and validates provenance. The region seed is a deterministic combination of Azgaar seed and pinned version, source cell ID, a pair of local region tile coordinates, and local adapter generation version. **Changing a town display name does not change the terrain**. Different source cells or tiles generate different regions; a full world source hash is stored to detect incompatible source changes.

The selected Azgaar cell supplies an initial **terrain constraint**: verified coast flag, source river presence or steep mountain elevation; world biome influences forest density. Town Forge then generates native water polygons, forests, mountain ridges and **provisional** regional roads. The result is an **independent versioned JSON geometry model** (not an SVG-only texture). An SVG preview and a Godot 2D debug viewer read that model.

### Hard limits in this first spike

- The map is a **conceptual 30 km square** using Town Forge's own 1000-unit landscape domain, NOT a claimed calibrated projection of Azgaar's entire world. Scale calibration is explicitly marked provisional.
- Source river existence constrains **river terrain**, but specific river course and river-boundary orientation have not yet been matched to Azgaar macro route geometry. Similarly, coast orientation is not yet sourced.
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
5. You should see forests, roads and, where generated, terrain/water features of one local area. Use **arrow keys** to pan, **mouse wheel** to zoom. The top line shows the source cell and local region terrain; its label deliberately warns that regional routes are not game-authoritative.
6. For comparisons, open the generated SVG previews in **tools/regiongen/.tmp/first.svg**, **second-burg.svg** and **other-tile.svg**. The first two represent different hometown cells; the third is a different region tile at the first cell.

This is a generator proof, not yet a travelling character, dungeon or town interior.

## What should follow in GAME-21

Validate actual source route/macro-river geometry, calibrate a physical scale against Azgaar, force compatible shared road/river/coast edge connectors for adjacent tiles, and store/cache generated region IDs under the immutable GameWorld / per-playthrough delta separation proven by GAME-7. Then connect a preview selector in the player-facing map rather than shipping this QA-only debug view.
