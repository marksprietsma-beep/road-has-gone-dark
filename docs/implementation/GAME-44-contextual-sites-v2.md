# GAME-44 — geography-bound v2 local exploration locations

## What is new (and what remains separate)

This is a **new opt-in site-generation namespace**, not an in-place edit to the original GAME-40 generator on draft PR #36. Source geography derives from the GAME-39 world-projection contract and GAME-46/47 `source_context` and constrained land mask. The old v1 `burg:<id>` source records, `region:v2`/v1 site IDs, player-discovery overrides, WorldGame saves and original upstream fixtures are **not rewritten or migrated**.

- The original Azgaar **hometown** keeps its exact original source position, its name and unchanged `burg:<source id>` site identity. Nearby source burgs stay unchanged in the source context. A v2 site generator is prohibited from minting additional Azgaar burgs.
- Farmsteads, inns, watchtowers and shrines are **eligible only when a true original Azgaar overland road or trail exists** in the neighbourhood. Candidate positions are sampled near those actual route segments. The existence of an inn, watchtower or route is *game-owned inference*, not evidence of original Azgaar source or safety; never mark roads protected or create a bridge.
- Ruins, camps and standing stones can occur away from towns and routes. Caves/mines require source highland cell heights. Dangerous-woods locations require existing illustrative forest near the actual dry-land location. **All** sites are rejected if over source sea/lakes, crossing poorly defined coastal edges, colliding with original burgs, roads or another generated site. The exact source features and provider decoration continue to be labelled separately.
- Rather than a hard-coded checklist, seeded local eligibility and actual source conditions produce **variable site counts and kinds**. There may legitimately be sparse or nearly empty regions. IDs are `<local-source-context.id>:site:v2:<kind>:<ordinal>`, seeded only by source world, context ID and kind; source hometown remains `burg:<id>`. Site *names* are presentation and cannot influence positioning or identity.
- A site may be `discovered`, `rumoured` or `hidden` by default, with `visited` available through overrides. **Player-facing SVG and the Godot F6 viewer** display only `discovered`/`visited` generated locations. Rumours expose non-positional, non-identifying text; hidden site names, IDs and coordinates are never passed to player views. The full debug JSON is a *developer-only* generation result and must not be served to the player's UI or saved as a player's discovered world.
- The approved GAME-42 hand-authored polygon icon registry is reused **unchanged**, independently of the site model. A separate Godot scene `scenes/debug/contextual_region_preview.tscn` reads identical glyphs, recognises genuine source burgs and lets developers inspect known locations. **H** is strictly a no-save developer reveal.

## Original route–coastline disagreements (visual review finding)

My six-map review identified an actual **source consistency conflict at Stormhorn**: Azgaar original sea-lane polylines pass across its original feature-defined land and portions of inland-road geometry pass through feature-defined water. This is **not** fixed by painting a road in a new place or presuming a ferry, bridge, navigable inlet or patrol. A distinct versioned `route-consistency.mjs` samples seven interior points along every original source segment against the genuine land/lake mask and reports either `SEA_ROUTE_INTERSECTS_SOURCE_LAND` or `OVERLAND_ROUTE_INTERSECTS_SOURCE_WATER`. It retains original segment indices and route IDs, without editing the original data.

New game-owned farms, inns, watchpoints and shrines can only use **overland approach segments whose samples are all on original dry land**. These are diagnostic *eligible approaches*, not verified roads or proof of protection. Source-coast conflicts are highlighted with **dashed amber-red warning geometry** in both SVG and Godot. The output's public site view still excludes all hidden location names, IDs and coordinates. The warning itself describes original source routes, not new secret POI positions.

These checks are conservative and not a physical crossing/landmask solution: long source route segments may contain narrow wet crossings between samples, source coastlines can be coarse, and true bridges cannot be determined from the present records. Do **not** silently assume consistency, and address the source model at a separate resolution/migration gate before pathfinding.

## Explicit migration and source limitations

**No automatic GAME-40 v1 save migration is implemented.** The old provisional v1 sites were centred around a fabricated tile location, while this v2 layer uses source world coordinates. Treat these as different region identities until a dedicated mapping/opt-in migration handles stored player knowledge, quests, placed site flags and save conflicts. Never silently reinterpret v1 coordinates as v2. The output embeds `migration.from_site_generation_v1: NOT_AUTOMATIC`.

The local view is 16 **Azgaar source-map units**, **NOT a calibrated 30 km**, and river centreline segments still approximate source cell chains. Real crossings, road protection, river mouths, detailed towns/dungeons and complete source land elevation aren't reconstructed. Original sea routes sometimes visually intersect original land polygons at source map resolution (notably near Stormhorn). Preserve classification, flag the limitation and do **not** invent land roads or ferries. This phase adds *generated inferred locations*, not proof that those sites would exist in Azgaar.

## Exact developer testing

The main CI workflow `Verify local source neighbourhoods` regenerates canonical worlds byte-identically, six constrained source-region composites and then six v2 populated previews; it verifies site collision, dry-land eligibility, world identity, variation and unknown-site privacy. It also imports Godot 4.7.2 and checks both the original GAME-47 and new GAME-44 F6 scenes.

From PowerShell **once PRs are ready for ordered checkout**:

```powershell
cd C:\projects\road-has-gone-dark
git fetch origin
git switch --create game-44-review origin/game-44-contextual-source-sites-v2
npm ci --prefix vendor/azgaar --ignore-scripts --no-audit --no-fund
node tools/worldgen/generate-azgaar.mjs --seed game-11-determinism --output tools/regiongen/.tmp/local-replayed-first.json --geometry-output tools/regiongen/.tmp/geography-game-11-determinism.json
node tools/worldgen/generate-azgaar.mjs --seed atlas-showcase-06 --output tools/regiongen/.tmp/local-replayed-second.json --geometry-output tools/regiongen/.tmp/geography-atlas-showcase.json
node tools/regiongen/generate-local-examples.mjs
node tools/regiongen/generate-constrained-examples.mjs
node tools/regiongen/generate-contextual-examples.mjs
node tests/regiongen/verify-contextual-sites-v2.mjs
```

To inspect in Godot, open `scenes/debug/contextual_region_preview.tscn` and press **F6**. Press **1–6** to switch source worlds and shore/river/highland examples, **F** to fit, **V** to toggle illustrative terrain and **H** to reveal developer-only hidden sites. Click a glyph to see source provenance and knowledge. CI does these data and interaction checks in headless mode; Mark need not test personally until user-facing integration is proposed.

This PR is a **data/preview proof**, not completed playable exploration. The full game screen, pathfinding, quest/spawn rewards, village interiors, DungeonGen instances and save migration remain future tickets. Personally inspect SVGs at normal and full resolution before accepting the artwork.
