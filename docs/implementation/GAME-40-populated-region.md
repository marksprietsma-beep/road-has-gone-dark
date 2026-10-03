# GAME-40 — Populated frontier-region development preview

This is a **real-data + game-generated POI proof** layered on GAME-21's pinned Town Forge landscape. It addresses Mark's visual review that coast/trees/roads alone are not an engaging RPG map. It does **not** claim the region is playable, world-space calibrated, seamless, patrolled, or fully discovered.

## Model and provenance

- Source: \`tests/worldgen/fixtures/game-11-determinism.json\` or another validated, immutable Azgaar world. The selected **real burg ID** and world SHA-256 must match the generated Town Forge region's source. The hometown retains \`burg:<numeric source ID>\`, label, and Settlemaker detail *hook*. It never fabricates a second macro burg.
- \`tools/regiongen/local-sites.mjs\` generates stable, versioned \`game_generated_local_site\` IDs beneath the region ID. It selects from a small contextual family: farm, inn, watchtower, shrine, ruins, cave, abandoned camp, ancient stones, dangerous woods and old mine. Locations are constrained to visible dry conceptual landscape and separated to reduce collisions. Sparse terrain may have fewer sites.
- Local maps use **provisional conceptual coordinates**. A deterministic seed uses real world seed and cell/tile identifiers, not the burg name. Actual Azgaar macro location projection, road ownership and connected tile edges belong to GAME-39. Town Forge roads in the preview are **not** guaranteed protected roads.
- Immutable objective site existence and \`knowledge\` (discovered, rumoured, hidden or visited) are separate. The player view reveals discovered/visited names/positions, emits only non-positional generic rumour hints and **does not export any IDs, names or coordinates for hidden sites**. The H toggle is a **developer-only debugging aid**; it is not a playthrough save action. Future saved local-site knowledge changes use the stable IDs, following GAME-7's playthrough delta boundary; no new simulation/gameplay state is fabricated here.
- Detailed towns (GAME-19), dungeons (GAME-20), world-space constraints and real travel/encounter simulation are future integrations.

## Verify in Windows PowerShell

From Mark's Windows clone, after the stacked PR's branch is available:

\`\`\`powershell
cd C:\projects\road-has-gone-dark
git status
git fetch origin
git switch --create game-40-review origin/game-40-direct-populated-region
npm ci --prefix vendor/azgaar --ignore-scripts --no-audit --no-fund
node tests/regiongen/verify-region.mjs
node tests/regiongen/verify-local-sites.mjs
\`\`\`

If a previous \`game-40-review\` local branch exists, use \`git switch game-40-review\` followed by \`git pull --ff-only origin game-40-direct-populated-region\` rather than creating it twice. Preserve local uncommitted changes before switching branches. Expected final output: \`PASS: GAME-21 ...\` and \`PASS: GAME-40 six populated regions...\`.

1. Open the Godot 4.7.2 project at \`C:\projects\road-has-gone-dark\`.
2. Open **\`scenes/debug/populated_region_preview.tscn\`** in the FileSystem panel.
3. Press **F6** (Run Current Scene).
4. Press **1–6** to compare inland, coast, river, mountain, estuary and second-world previews. Press **F** to fit the map; arrows pan; mouse wheel zooms. **Click an icon** to inspect type, name, origin, discovery state and description. Press **H** to toggle **developer-only reveal**, and switch it off to check the hidden positions disappear.
5. Look for a populated **source-backed hometown**, distinguishable roads/fields/ruins, sparse wilderness and actual clues. Report a screenshot (at least inland and coastal/river) and which elements feel repetitive, awkward or too barren.

### Visual review artifacts

The \`Verify populated local region\` GitHub Actions workflow uploads \`game-40-populated-region-examples\` containing six SVG maps and one representative structured JSON. Download and open the SVG files in your browser to review the layout before Godot testing. **A green CI job is not equivalent to visual acceptance.**

### Constraints and limitations

These are **first-pass** representative game-generated site types, not fully scripted quests or true wilderness ecology. Their terrain classification uses current Town Forge/authoritative Azgaar context; exact macro-location distribution requires GAME-39. Maps share the 1000-unit Town Forge conceptual square, not a calibrated 30-km-world projection. Further art iterations may draw on the approved Game-icons visual taxonomy, but should preserve POI IDs and knowledge filtering. Detailed named dungeon maps and settlement layouts have intentionally not been generated.

## GAME-42 visual pass (direct GitHub recovery)

GAME-42 replaces diagnostic site dots/black rectangles with identifiable parchment-and-ink site glyphs in both Node SVG and Godot F6. Site coordinates, terrain generation, provenance, stable IDs and per-playthrough knowledge semantics are **unchanged**. These are provisional conceptual regional maps, not a seamlessly world-projected set of tiles (GAME-39 remains outstanding).

- `assets/map/region-site-icons.json` is a **shared decorative symbol registry**, versioned separately from the world model. Both `tools/regiongen/site-icons.mjs` and `scripts/debug/populated_region_preview.gd` read this registry. To replace/expand the artwork, edit the icon registry or presentation code, **never** the canonical site types, IDs, save data or pinned upstream generators.
- 11 distinguishable silhouettes represent towns, farms, inns, watchtowers, shrines, ruins, caves, abandoned camps, standing stones, dangerous woods and mines. Unseen sites are still filtered out of normal SVG/Godot display; H reveals them only in developer mode.
- At normal map scale, only the hometown and a few important locations receive labels. Remaining places are identifiable by symbols and the click-to-inspect sidebar. Text labels use a simple overlap/boundary test and restrained parchment background. Forest terrain now receives an illustrated evergreen pattern rather than flat colour alone.
- Keep the existing exact PowerShell instructions and `scenes/debug/populated_region_preview.tscn` F6 testing procedure above. Run the full generated-world Node suite and Godot 4.7.2 CI and review the six SVGs uploaded to the populated-region workflow. These are a human visual checkpoint, **not** an acceptance claim or production art approval.
