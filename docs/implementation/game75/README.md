# GAME-75 — meaningful origin context

Production base: `3350aed73aa22f2f144ae4613f054ff81ab0ca34` (accepted GAME-76).
Initial assessment was pushed and independently verified before implementation:
`fed63bb1b32abb545b763967feba4ee3d5e59118`.

New Game now explains geographical differences at World, Region, Hometown and
Confirm. The accepted black/gold controls, map highlighting and font sizes remain.
Generation, deletion, independent saves and the Party Creation Next handoff remain
GAME-76/74/7 responsibilities. No gameplay, Continue or party editing was added.

[Comparison overview](screenshots/contact-sheet.png) — genuine captures resized
for comparison; full-resolution originals are linked below. No annotations were
added inside the game images.

## What a player can compare

Names are not needed to explain these real choices:

| Choice | Actual difference | Screenshot |
| --- | --- | --- |
| World I / World II | Tropical woodland versus grassland as the strongest landscape | [I](screenshots/01-world-i.png), [II](screenshots/02-world-ii.png) |
| Tusmukmia / Prequm | Inland temperate woodland versus coastal tropical woodland with recorded ports; moderate versus sparse settlement concentration within their respective parent states | [Inland province](screenshots/region-forest.png), [Coastal province](screenshots/region-coastal_port.png) |
| Maura / Klovskitaue | Inland woodland village versus coastal rainforest town with a recorded port; both have a verified road point | [Inland home](screenshots/home-forest.png), [Coastal port](screenshots/home-coastal_port.png) |
| Lauerila / Maura | Recorded walls versus no walls recorded | [Walled home](screenshots/home-walled.png), [Unwalled home](screenshots/home-unwalled.png) |
| Turnan / Maura | No public town inside the source-relative radius versus a close cluster including a larger walled neighbour | [Sparse surroundings](screenshots/home-sparse.png), [Clustered surroundings](screenshots/home-clustered.png) |

Names in this table are display labels, never lookup keys. Exact source identities,
selected political ownership and the claims for every screenshot are in
[visual-proof.json](visual-proof.json). Province concentrations are relative to
other provinces in the **same state**, not a universal cross-world density rating.

Other real captures: [fresh generated world](screenshots/03-generated-world.png),
[generated region](screenshots/generated-region.png),
[generated hometown](screenshots/generated-hometown.png),
[whole inland state](screenshots/state-forest.png),
[whole coastal state](screenshots/state-coastal_port.png),
[confirmation](screenshots/confirm-coastal-port.png),
[640×360](screenshots/confirm-640x360.png),
[2560×1440](screenshots/confirm-2560x1440.png),
[successful save/handoff](screenshots/origin-established.png).
All images are actual Godot 4.6.3 viewport captures, not generated illustrations.

## Architecture and claim rules

`OriginContext` receives GAME-7's immutable identity and the **same validated
canonical snapshot** already supplied by GAME-76 to the preview. It defensively
copies that snapshot, removes markers and indexes public settlements and routes.
It does not load/save worlds, invent eligibility or replace the GameWorld model.
The UI caches one service per immutable world ID and only renders returned text.
Restored ItemLists scroll the selected name into view on Back; actual keyboard
selection and a below-viewport return are exercised in the capture regression.
Output includes `summary`, short `tags`, structured `facts`, versioned `rules`
and the immutable `world_id`. Returned data is deep-copied. Prose is local,
fixed, deterministic and independent of display names.

| Claim / rule ID | Supporting source and decision |
| --- | --- |
| Settlement group, WALLED, PORT / `public-burg-port-walls-v1` | Direct original `burg.group`, `walls == true`, numeric `port > 0`. Missing fields remain null; absence is never a claim that maritime activity is impossible. |
| Landscape / `land-biome-area-v1`, `burg-cell-biome-v1` | World/area: sum `cells.area` for land (`height >= 20`) by source biome. Largest sum wins, biome ID breaks ties. Home: its actual cell biome. Transparent player synonyms include deciduous forest → temperate woodland and seasonal forest → tropical woodland. World may include the second biome if ≥15% of land area and both short names fit. |
| Landmass / `largest-land-feature-share-v1` | Source land feature IDs and land-cell area. Largest feature ≥75%: one main landmass dominates; 50–75%: more than one landmass; <50%: land spread across several landmasses. Missing feature classification produces unavailable context. These are modest visual guidelines, not a narrative world type. |
| Coastal / lake shores / inland / `ocean-lake-cell-neighbours-v1`, `area-water-neighbours-v1` | A land cell neighbouring water with source feature type `ocean` is coastal; lake-only adjacency is lakeside. Neither is inland. Unknown water feature remains unknown. Area is coastal if any owned land cell satisfies the sea criterion, lakeside if lake-only, otherwise inland. Coastline presence does not mean most of the province is coastal. |
| World coast distribution / `public-coastal-town-share-v1` | At least two thirds of public towns classified coastal or away from sea yields the corresponding “Most towns…” sentence. Otherwise both known categories yield coastal and inland settlements. Unknown classifications cannot silently count as inland. |
| Region concentration / `within-peer-density-tertiles-v1` | Public positive-population towns / source land-cell area. States compare within their world; provinces compare within their parent state. Strictly below lower tertile: sparsely settled; strictly above upper tertile: densely settled; ties/middle: moderately settled. Fewer than three peers: recorded settlements. Zero area: unavailable. No town: explicitly no public settlements. Facts retain actual density and sorted peer densities. |
| ROAD / ROAD LINKS / TRAIL / `route-exact-point-v1` | Original `roads` / `trails` route point must match the burg's cell **and** coordinates within 0.02 source map units (serialization rounding). One unique road record: ROAD; ≥2: ROAD LINKS; trail-only: TRAIL. Sea routes, merely crossing the cell or passing nearby, hidden/removed routes are excluded. Route-record count is not a graph degree, trade or travel claim. Unverified access is omitted. |
| RIVER PORT / `recorded-inland-port-river-cell-v1` | Recorded positive port, inland classification, positive cell river ID **and** original matching river record containing that cell. The pinned burg generator explicitly promotes navigable inland river ports. Port feature IDs may identify downstream water, including ocean from a lake outlet; port IDs never determine coastline. Ordinary cell-river adjacency alone is omitted. |
| Nearby / cluster / `same-feature-median-nearest-radius-v1` | Radius = twice median nearest-neighbour distances among all public settlements on the same known source land feature. Towns inside that radius and on the same feature are nearby; ≥3 forms a close cluster, 1–2 is a few neighbours, zero explicitly reports no nearby towns on this landmass. Insufficient information is unavailable. Facts retain original burg IDs, individual source-coordinate distances and radius. No path accessibility or physical distance is implied. |
| Larger/walled neighbour / `source-population-comparison-v1` | Nearby town population exceeds both selected population and GAME-7's small-home ceiling (5); walls must be explicit true for the fortified wording. No protection relationship is inferred. |

Removed/hidden/nonpositive-population settlements never participate in aggregates,
proximity thresholds or returned facts. Markers/POIs, economic and diplomatic
simulation records, culture-based personalities and invented danger/prosperity
are never consulted. Unsupported social facts and ordinary river proximity are
omitted. The source, identity and save schemas are unchanged.

Indexes and summaries are reused during selection. Nearest-neighbour analysis is
one pairwise pass per world (quadratic in public towns, grouped by land feature);
region concentration caches peer densities. The actual tested worlds have
749–950 source settlements. This is a small local service, not a procedural prose
framework or spatial-travel system. A much larger generator recipe would warrant
profiling this pass before expanding the recipe.

## Repeatable verification

Requires Godot **4.6.3** and the accepted GAME-76 platform `worldgen-helper` beside
`project.godot` (or `GAME76_HELPER_ROOT` pointing to it). Players still require no
system Node or browser; tests also invoke the bundled runtime directly.

```sh
python tests/origin_context/run-tests.py --visual --regressions
```

For Linux without a desktop:

```sh
xvfb-run -a -s '-screen 0 3840x2160x24' python tests/origin_context/run-tests.py --visual --regressions
```

Windows PowerShell, after installing the accepted helper:

```powershell
$env:GODOT_BIN = 'C:\Tools\Godot_v4.6.3-stable_win64_console.exe'
python tests/origin_context/run-tests.py --regressions
python tests/origin_context/run-tests.py --visual
```

This generates **three fresh genuine worlds** with explicit seeds, locked pinned
helper/runtime and no PATH Node fallback. It derives context for both presets and
all three fresh outputs, checks every eligible home, claims and political areas,
then exercises the existing persistence/library and renderer tests. Scripts may
refresh existing GAME-74/76 QA outputs; this PR retains their accepted historical
images and commits new GAME-75 evidence in this directory.

[generated-proof.json](generated-proof.json) records seeds, generator identity and
full source hashes. [context-proof.json](context-proof.json) retains contrasting
source burg IDs and facts. [Test results](TEST-RESULTS.md) records actual executed
results and platform CI. All canonical fixture bytes remain unchanged.

## Windows player review

1. Open this branch in Godot 4.6.3 with the accepted GAME-76 Windows helper beside
   `project.godot`. Launch, skip intro with Escape, select New Game with Enter.
2. On WORLD use Up/Down to compare World I and II. Their landscapes differ.
   Generate New World still creates a genuine reusable world; its context updates.
3. Choose World I → REGION. Compare Kausalo / Tusmukmia (inland woodland) with
   Ulentoma / Prequm (coast/ports). “Across this state” shows the whole-state summary.
4. Proceed to HOMETOWN. In Tusmukmia select Maura; in Prequm select Klovskitaue.
   Compare inland road/woodland with coastal recorded port/rainforest. Walls and
   nearby-settlement statements are factual differences, never difficulty ratings.
5. Confirm page retains this context. Back/Escape preserve or invalidate choices
   through the existing flow. Cancel before confirming creates no save.
6. Confirm once: origin is saved and immediately reload-validated; Party Creation
   Next is the stopping point. Review Origin cannot create another save. Continue
   remains disabled. Check ordinary 1280×720 and larger Windows desktop scaling.
7. Existing generate/delete/cancel behaviour is unchanged; worlds referenced by a
   playthrough remain protected against deletion. No acceptance or merge is implied.

## Limits and deliberate omissions

Coast/biome is coarse source-cell context, not exact village shoreline or forest
extent. Concentration uses source area and peer distributions, not physical land
measurements. Neighbour distance is qualitative straight-line source geometry,
not a route, travel time, safety or across-water connection. A port record does not
prove ocean coastline; an inland river port is possible. Road point matching is
conservative and can omit ambiguous access. Some choices genuinely share the same
facts and therefore wording; no colourful adjectives are invented to force variety.
The existing eight-home list and eligibility ordering are unchanged; no ranking
language remains. No character creation, GAME-8 expansion, GAME-73 refinements,
canonical mutation, generator changes, new dependencies or research PR merges.
