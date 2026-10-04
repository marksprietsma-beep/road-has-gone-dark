# GAME-59: local/world visual consistency

The contextual preview now consumes the same Game-icons SVG assets as the
world map. Godot uses MapIconProvider; SVG previews embed those actual assets.
The original settlement role is looked up in the immutable canonical world.
All local symbols use a 32-display-unit marker with 26-unit art, independent
of physical object size. Source burg positions and landscape footprints do
not change. Legacy previews keep their prior renderer.

Local semantic aliases: farmstead/hamlet, roadside inn/inns, watchtower/fort,
shrine/monastery, old mine/mine, abandoned camp/encounters,
ancient stones/statues, dangerous woods/sacred-forests. The last alias reuses
the forest silhouette only; it does not declare a sacred place.

## Scale

The window remains 16 by 16 original source units (area 256). The pointy local
hex spacing remains one source unit, hex area sqrt(3)/2. World cells are
irregular Voronoi cells, not these local hexes. Source cell areas yield:

| Home | Window / home-cell area | Home-cell / local-hex area |
| --- | ---: | ---: |
| Linjeira | 4.06 | 72.75 |
| Hurepoki | 1.77 | 167.43 |
| Invermor | 3.51 | 84.29 |
| Stormhorn | 3.32 | 88.91 |
| Ris | 2.02 | 146.65 |
| Kindum | 1.92 | 153.58 |

These are area equivalents, not counts of complete cells contained. No
kilometre or hourly rate is asserted. Generate the source-coordinate comparison
with `node tools/regiongen/review-shared-icons.mjs`. Its cell outlines are
reconstructed from original centres; the original vertex connectivity is not
in the canonical fixture. Coastlines, roads and burgs remain source-backed.
Keep the current footprint; add meaningful discoveries rather than stretching
the map or revealing hidden POIs to make it look busy.

## Hex occupants

The separately named `.encounter.svg` shows brigands and hill-monsters as a
labelled mock-up. They sit at existing, wholly dry hex centres, avoid known
sites and burgs, and never consult hidden POI positions. The optional JSON layer
is explicitly MOCKUP_NOT_SIMULATION. No spawns, movement, combat, saves or
player travel rules change. Normal SVG and Godot maps do not show mock enemies.
An eventual encounter system can associate visible occupant records with the
world-anchored axial cell and use these symbols as its presentation layer.

## Review

Six source contexts, deterministic manifests, shared actual SVG assets,
dry-placement checks, hidden privacy, contextual viewer and expedition smoke
tests. SVG output was rasterised and visually checked, then corrected for
nested-SVG overlay insertion and comparison-caption overlap. Native Godot
asset loading and UI smoke tests pass; fresh full native screenshots were not
available because display setup was blocked. Earlier native screenshots are
not represented as evidence of this change.

Work remains local pending explicit approval to publish the stacked branch.
