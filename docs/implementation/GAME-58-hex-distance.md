# Optional hex distance overlay

X toggles a pointy hex grid in the contextual region preview and expedition
prototype. Click a visible known local site in the contextual preview to show
its geometric hex distance from the hometown. Normal landscape remains the
default. Grid spacing is one original Azgaar source unit between adjacent
centres, globally anchored at the source-world origin; adjacent crops use the
same axial cell identities. These are new display cells, not Azgaar Voronoi
cells, surveyed terrain, kilometres or a campaign/save schema.

The contextual generator also emits `.hex.svg` with the grid and a numbered
distance ruler to the farthest already-visible site, where one exists. No
hidden or rumoured site determines that ruler. It represents the unobstructed
hex distance; it is not a walkable path and can cross source water. River
crossings, pathfinding, boats and movement permissions remain unimplemented.
The existing expedition durations are unchanged.

Travel time can later sum the cost of each cell on an actual permitted route:
base time × terrain cost × party/weather modifier. The actual base duration,
physical hex size and terrain/crossing rules are still design decisions.
Display-only hexes do not silently resolve them.

Validation: `verify-hex-overlay.mjs` checks round trips including negative
coordinates, all six neighbours, global world anchoring, hometown zero distance,
six generated overlays and hidden-site privacy. Contextual Godot smoke checks X
on/off and zero-distance conversion. `capture-landscape.gd -- --hex-review`
captures six actual in-engine hex screenshots under a desktop.
