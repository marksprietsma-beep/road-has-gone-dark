# GAME-60: connected hex route preview

The contextual map now has an optional P route preview. It displays a connected
candidate route to an originally known site using the same world-anchored hexes
and Game-icons. X remains an independent geometric grid. P and E are mutually
exclusive developer overlays. Click another known site to change the route;
switching regions resets the preview. Gameplay expedition controls ignore P.

## What is calculated

Only wholly source-dry hexes enter the graph. Coast and lake boundary
intersections, enclosed lakes and off-window hexes are excluded using the same
conservative geometric checks as the occupant proof. Neighbours differ by one
axial step. Dijkstra calculates both the shortest dry-hex path and a path with
the lowest provisional terrain effort. The home and destination must already
lie in accepted cells; blocked endpoints are never snapped across water.

| Illustrative terrain | Provisional effort per open-hex step |
| --- | ---: |
| Open | 1 |
| Woodland (canopy ≥ 0.57) | +0.5 |
| Rough ground (height ≥ 69) | +0.75 |

The edge cost averages the two cells' terrain costs. Woodland and rough
additions combine. These are tuning assumptions based on the inferred visual
field, not surveyed terrain. Roads get no automatic discount: being near a
source line does not establish a continuous, safe route. Mock bandits/monsters
do not affect effort. Within-cell endpoint connectors are displayed but do not
add separate effort; this is a coarse hex comparison.

Geometric distance, shortest dry-hex steps, weighted route steps and effort are
separate fields. Kilometres and hours are explicitly UNCALIBRATED. A future
selected minutes-per-effort value could convert effort into a scenario estimate;
it would still need an approved physical scale and actual traversal rules.

Approximate river-line intersections are marked with red rings and an
unverified-crossing count, including routes overlapping a river line. No bridge
is inferred. A dry-hex route is **not a verified traversable route**; river
crossings, slopes, obstacles and patrols remain unknown.

## Review findings

Twelve originally known destinations have connected candidate routes in the six
contexts. Two Kindum destinations prefer a longer route with lower provisional
effort. Hurepoki's Ashfield Croft route flags one approximate river crossing.
Ris has no originally known destination beyond home, so the preview shows
"No known destination yet" without disclosing any hidden or rumoured POI.

The preview is an optional generated layer with matching source context/world
fingerprints. It consumes no hidden or rumoured coordinates and does not consult
occupant mock-ups. Removing these presentation layers leaves expedition journey
hours, supplies and danger unchanged. No player-save, provider fixture,
settlement/site ID or source geography migration is involved.

## Validation and review

`node tests/regiongen/verify-hex-route-preview.mjs` checks deterministic rebuilds,
all twelve routes, accepted dry cells, adjacent path steps, reconstructed costs,
hidden-input independence, foreign context rejection, same-cell routes,
synthetic obstacle detours/disconnection/blocked endpoints, weighted cheaper
detours, symmetric effort, and crossing/parallel/overlapping river lines.

`tests/regiongen/smoke-hex-route-preview.gd` checks P, site inspection, enabled
draw frames, E/P exclusivity, X independence, region reset, absent/foreign-layer
guards, hidden-site privacy, and disabled gameplay preview. Existing expedition
tests compare travel with and without both generated presentation layers.

SVG maps are rasterised and inspected across all six examples. They remain SVG
renderer evidence; no fresh full native screenshot is claimed. The capture
helper supports `-- --route-review` in an environment with a display.

Next: choose a time/scale calibration and decide how actual crossing knowledge
and terrain authority should govern routes before connecting this to gameplay.
Work is committed locally; publication remains pending explicit approval.
