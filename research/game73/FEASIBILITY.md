# Pinned Settlemaker feasibility and architectural recommendation

Inspected revision: [d5cf3590cf59e1d382110d25a6910f12507299e2](https://github.com/barrulus/settlemaker/tree/d5cf3590cf59e1d382110d25a6910f12507299e2).
Seven entry-point/input/model/license files were independently fetched and matched
the previously inspected checkout. [Hash manifest](evidence/engine-source-verification.json)
and [executed verification](evidence/engine-source-tests.txt). No engine execution,
new engine dependency, engine vendoring or approved town regeneration occurred.
The archived GAME-63 requests and committed GAME-67 GeoJSON were also inspected.

| Technique | Actual pinned capability | Practical constraint |
| --- | --- | --- |
| Settlement type / size | `engine: auto/village/city`; auto switches above 1,000 input people. Population and urban density affect building/ward budgets. | Azgaar fixture population is not saved people. GAME-63's ×1,000 conversion was an inferred default. Village planner units and city mesh units differ. |
| Walls / citadel | Source flags request features; model exposes `degradedFlags` when geometry cannot honour them. | Flags alone do not prove a wall was produced. Albanes preserved geometry actually contains two wall features and 26 towers. |
| Port / coast | `port` requests infrastructure; `oceanBearing` supplies a synthetic half-plane, independent of port. `harbourSize` is supported. | Port is not a shoreline shape or a calibrated harbour size. Existing Thilranlena uses the NW bearing and small harbour. |
| Road approaches | Independent `roadBearings` with route IDs/types; matched entrance route IDs and errors are exported. | `through` is a growth hint, not an automatic opposite exit. Streets/gates are approximate. Preserved Albanes entrance errors are roughly 6–17°, not exact alignment. |
| Supplied coast polygons | `coastlineGeometry` filled polygons are supported in planner-local coordinates. | No automatic Azgaar-to-provider transform. Village metres versus city mesh units make uncalibrated polygon copying inappropriate. |
| Measured water | Village `waterContext` validates units/width information; city rejects that contract. | Canonical source lacks calibrated local river width and world-to-provider scale. Unknowns must remain unknown; supplying invented widths is not a shortcut. |
| Biome / vegetation / fields | `biome` selects art/theme and influences layout. City/village interiors have their own landscape rules. | No verified public API for arbitrary canonical forest polygons, exact farm boundaries or mandatory clearing radius. Internal rules are not a supported provider-neutral contract. |
| Layout selection | Seed/options repeat layout/art; output metadata timestamp needs control. A bounded candidate selection process is conceptually possible. | No candidates were generated here; success rate/performance is unknown. Do not replace approved output to search for an unverified improvement. |
| Whole-art rotation | A reversible display transform works without engine changes. | Rotates buildings, roads and waterfront together; selection polygons would need the identical presentation transform later. Our experiment shows it can worsen geography. |
| Cropping / composition | Preserved output can be displayed with an independent border, bearing diagram and ownership envelope. | Cropping can hide gates/harbour/important fields. It does not repair source relationships. Full-frame original/public art remains preserved. |

Sources: [input fields](https://github.com/barrulus/settlemaker/blob/d5cf3590cf59e1d382110d25a6910f12507299e2/src/input/azgaar-input.ts),
[water validation](https://github.com/barrulus/settlemaker/blob/d5cf3590cf59e1d382110d25a6910f12507299e2/src/input/water-context.ts),
[entry point](https://github.com/barrulus/settlemaker/blob/d5cf3590cf59e1d382110d25a6910f12507299e2/src/index.ts),
[model](https://github.com/barrulus/settlemaker/blob/d5cf3590cf59e1d382110d25a6910f12507299e2/src/generator/model.ts).
These are inspected capabilities, not broad-seed runtime guarantees.

## The measured rotation experiment

Thilranlena's original burg-to-wet-cell bearing is **336.585°**. Its visible
synthetic waterfront's length-weighted normal is **337.456°** (0.871° discrepancy).
The parent-cell-centre direction is **322.075°**. This difference comes from using
a different anchor, not proof that the preserved coastline is wrong.

Rotating the preserved public art −15.380° toward that cell-centre approximation
makes the original-burg water discrepancy **14.510°** and increases the two
route-matched entrance errors from **0.3/3.1°** to **15.08/12.28°**. The actual
rotated SVG/raster is a labelled rejected display experiment. Nothing is applied
to original art, source polygons, facilities or navigation.

The west `azgaar:54` foot/trail match uses exported entrance `g25`, typed `harbour`.
That semantic combination needs review before access/travel rules consume it. Its
point is outside the filled synthetic water polygon, so this does **not** establish
that the land trail requires walking through water. A harbour-side land connection
can be legitimate. No confirmed wrong-side coastline or inland-port contradiction
was found in the three preserved cases.

## Smallest next implementation step — recommendation only

Keep the three existing detailed maps and their inputs. Add a presentation/context
acceptance check at a future **research** boundary: verify world/burg/cell identity,
source water side, route IDs/approximate bearings and fortification output separately.
Treat mixed land/harbour entrances as potentially dual-use until a source-backed
access decision exists; do not silently convert a land trail to a sea-only route.
Use an explicit available-town catalog so visible neighbouring burgs never acquire
an invented detailed map.

For relative illustration, choose a small source-relative footprint budget from
population/importance, cap it against owned dry land and neighbours, and use the
same world-coordinate clearing envelope in every view. GAME-62 already has globally
anchored scalar scenery/tree centres; its fixed **display-unit** clearings, tree
radii and filtering cause visible seams. A future visual-only clearing/radius policy
could reduce those seams without touching authoritative geography. This research
measures the seams; it does not change the accepted generator.

Use the simple context object only when a real downstream consumer needs it. Cache
validated immutable geometry/context per world/cell if it becomes a runtime consumer;
this proof is an offline audit, not a per-frame generation API. Keep
provider input conversion separate; avoid a multi-provider framework, exact coast
fitting, save migration or kilometre conversion. Any future generation/candidate
selection requires a separate licensing and population/scale decision. No GAME-19
integration is proposed or started here.

## Licensing limits

Settlemaker engine is GPL-3.0-only. Its default art libraries have separate CC BY
terms and rendered-output provisions; Copperline has separate GPL terms. Existing
rendered public research art and its original attributions are reused, not new
art libraries or engine source. See [existing provenance/licensing](../game67/README.md#provenance-licensing-and-integration-risks)
and [original-art preparation](../game69/ALIGNMENT.md). This proof is not clearance
for engine integration or redistribution of its libraries.
