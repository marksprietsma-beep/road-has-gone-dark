# GAME-51 — inferred local terrain for source-authority comparisons

This is a second, **explicitly non-authoritative** GAME-49 slice. It is based on [GAME-49 PR #43](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/43), itself stacked on the independent GAME-48 calibration experiment.

## Why this is not new source geography

Azgaar's original settlements, coastline/lake vertices and routes are authoritative **at the original world-map resolution**, not a footstep or mountain-pass survey. With an explicitly *hypothetical Earth-equivalent* 30 km reference, only around zero to one Azgaar original terrain-cell centres often fall inside a local window. Any detailed landscape here is an illustration extrapolated from **nearby coarse source biome/height conditions**, not a physically surveyed walkable map.

`inferred-fine-terrain.mjs` implements an opt-in v1 field: a fixed 33×33 vertex preview grid evaluated at **original global Azgaar world coordinates**, using four nearest macro cell samples for approximate broad elevation and woodland tendency. A deterministic, globally seeded multi-scale lattice-noise field produces smaller variation. Two overlapping neighbourhoods evaluate to identical inferred height/forest tendency at the exact same original source position, irrespective of burg name, context ID or drawing viewport; this does *not* yet prove traversable seam compatibility.

The `inferred-fine:v1:` record has a **different identity** from macro SourceAuthority, original GameWorld, 16-source-unit exploration windows, GAME-40 v1 sites and GAME-44 v2 sites. The existing saves and all provider/vendor/fixture files remain untouched. No migration is automatic.

## Presentation-only rendering

`render-inferred-fine.mjs` draws continuous layered elevation bands and clustered woodland masses in the SVG maps, rather than random mini-fir and chevron glyphs. Inferred rendering is **clipped by a mask made from original Azgaar land polygons minus original freshwater lake polygons**; the inferred field does not redefine shoreline. Original route polylines, burgs, lake and macro coast provenance are retained independently; original sea lanes remain behind land fill, not a made-up road through shore.

Six source worlds/contexts (two original Azgaar seeds × coast/river/highland) have **both** the previous `authority-*.svg` and new `fine-*.svg` evidence. The SourceAuthority comparison/Godot viewer can show inferred detail using its existing I toggle, but never turns it into an obstacle or terrain permission for players. The detailed field is not injected into gameplay, pathfinding, creature placement or saved discovery.

## Unresolved decisions

- Planetary radius and the real physical size of a local region remain **unknown**. The 30 km reference examples *assume* an Earth-size radius and are **not** a decision that the game world must be Earth-sized.
- No safe or patrolled roads, bridges, river mouths, exact rivers, harbour ramps, reliable walking barriers, passes, or access terrain are established by the inferred hills/forests.
- Noise may produce plausible **illustrative** woodland and relief, but the source data is too sparse to validate exact shapes. Full playable local-terrain generation still needs an explicitly authored design policy, actual traversal constraints, and versioned contracts between global and local maps.
- GAME-44 contextual POIs are on a **sibling branch PR #42**. Do not silently rebase one into the other or claim its old v1 saves are migrated.

CI verifies immutable canonical replay, original source-authority checks, inferred-field determinism and shared-coordinate invariance, source-water visual masking, six SVG XML files and Godot smoke. Human visual review of **all six SVGs** is still required before accepting even an illustration style. This is not a playable map.
