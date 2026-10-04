# Local landscape presentation — GAME-57

Based on PR #47 (`dbd4259`), keeping its expedition loop and the unmerged
dependency stack intact. No source fixture, pinned vendor, campaign/save or
site-generation identity changes. The new optional `landscape_presentation_v1`
is disposable illustration data, not a source/traversal schema.

## Result

The six contextual maps now share a calmer 64×64 world-coordinate art field,
forest masses with canopy/pine detail, restrained relief shading/contours,
source-burg-centred schematic buildings, clearings and fields, and water
ripples. Ground/object primitives are generated once and consumed by both SVG
and Godot. The legacy `inferred_fine_v1` remains byte-compatible. No hidden or
rumoured site layer is consumed by the scenery generator; it only reads the
canonical world and source context. Existing knowledge controls, source towns,
roads, shore and water classification remain authoritative at source resolution.

Town artwork does not represent surveyed buildings or physical town size.
Clearings and field footprints are stylistic, source units remain uncalibrated,
and artwork does not establish paths, safe roads, bridges or walking terrain.
The art sampler is globally deterministic; local grid interpolation, clipping,
town clearings and context-specific route exclusions are presentation choices,
not a proof of seamless walkable neighbourhoods. The legacy field and new art
have distinct namespaces and no automatic migration.

## Actual review iterations

1. Replayed both immutable worlds and rendered all six original maps. Found
   aliasing: short-wave noise sampled into 32 intervals produced angular,
   camouflage-like forest patches; tiny burg markers lacked visible settlement
   context and diagnostic panels dominated the map.
2. Added the independent calmer art sampler and shared scenery primitives.
   Rendered six SVGs; caught overlapping field plots, trees through fields and
   visible square shading. Removed overlaps, excluded canopy from fields,
   softened shading and added contours.
3. Captured all six maps with the actual Godot 4.7.2 OpenGL renderer. Found
   coastline stair-stepping caused by rejecting every mixed land/water triangle.
   Border triangles now intersect original source land; lakes repaint above art.
   Added biome/elevation-sensitive tree silhouettes, irregular town clearings,
   light water texture and removed orphan furrows after a field is rejected.

Visual assessment: materially more readable and populated, worth showing as a
cartographic prototype. Remaining limitations: sparse canonical source geometry,
schematic buildings, broad elevation bands and simple silhouettes. This is not
finished illustrated/pixel artwork, detailed town interiors or fine pathfinding.

## Validation and review

Generate the source geometry/local/constrained/contextual examples using the
existing local-source-context workflow. Run:

```bash
node tests/regiongen/verify-landscape-presentation.mjs
node tests/regiongen/verify-contextual-sites-v2.mjs
node tests/regiongen/verify-constrained-region.mjs
node tests/regiongen/verify-local-context.mjs
godot --headless --path . --script res://tests/regiongen/smoke-contextual-sites.gd
godot --headless --path . --script res://tests/regiongen/smoke-expedition.gd
godot --headless --path . --script res://tests/regiongen/smoke-constrained-preview.gd
```

`capture-landscape.gd` exports six actual Godot screenshots under a desktop/Xvfb;
CI uploads them beside the SVGs. Review `scenes/debug/contextual_region_preview.tscn`
with F6, 1–6 to change region, V for scenery, wheel to zoom, arrows to pan and
click known icons to inspect. H/A remain developer-only and are disabled in the
expedition scene. No local action is required to inspect the supplied screenshots.
