# GAME-55 — first interactive expedition loop

## What is actually playable now

This is the **first party/exploration vertical slice**, rather than another static generated map comparison. In Godot, launch exactly `scenes/gameplay/expedition_prototype.tscn` with **F6** (Run Current Scene). The preview uses real generated Azgaar source geography and the GAME-53 contextual-location+inferred-terrain layers. It **does not replace** the main menu, the New Game placeholder, canonical world JSON or existing save format.

The expedition starts with **three travellers** at the unchanged original source hometown. It keeps session-only **supplies, elapsed hours, danger, clues and a local discovery journal**. The player may select an already discovered site, undertake an **abstract multi-turn journey**, investigate it cautiously or recklessly for different clue/danger consequences, scout for one nearby rumoured/hidden location, and return to the original town to resupply. Revisiting an already investigated location cannot duplicate its rewards. Six world examples are available; switching changes the session without leaking previous world knowledge.

### Controls

- Click a **visible** site pictogram to select it; **T** undertakes an abstract journey to the selection (when enough supplies are available, and the direct sampled corridor does not contradict source sea/lake geometry).
- **S** scouts for a nearby lead, consuming one supply and two hours. Original hidden site names, IDs, positions and icons do not appear before discovery; hidden-site developer mode is **disabled**, including **H**.
- At a destination, **C** investigates cautiously, spending more time and supply but gaining one clue without added danger. **B** takes a reckless approach, gaining two clues and raising danger by two. An investigated site becomes visited.
- **R** returns the party to the original hometown and replenishes supplies, but refuses a directly contradicted source-water corridor.
- **1–6** switch among original two-world × shore/river/highland examples. **F** fits, **V** toggles inferred scenery, **arrow keys** pan, **mouse wheel** zoom, **Escape** closes this isolated scene. The QA route-audit toggle **A** is also disabled in this preview.

### Explicitly *not* simulated

There is no physically navigable scene, obstacle mesh, safe or patrolled road network, inferred bridge, ford, real local road junction, settlement interior, party combat, encounter balancing, inventory or persistent expedition save. The 16 Azgaar-source-unit window is **uncalibrated** (not physically 30 km). A successful abstract journey asserts only that a straight sampled line is **not contradicted by original macro sea/lakes**, **not** that a legitimate real-world walking trail or protected road exists. Fine terrain is *illustrative*, not authoritative. Additional narrative/party choice will depend on later mechanics; the two investigation approaches here prove that decisions can have different state consequences.

Do **not** migrate `local_sites_v2` into the existing `GamePlaythroughStore` yet: that v1 service only accepts original `poi:<source ID>` records; generated site IDs need a deliberate new version and migration contract, rather than overwriting existing campaigns. All GAME-55 mutable state is per-preview instance and is discarded when the scene closes.

## Tests and acceptance

GitHub Actions `Verify local source neighbourhoods` regenerates immutable original worlds, terrain, six contextual regions and runs `tests/regiongen/smoke-expedition.gd` under **Godot 4.7.2**. This checks six source instances, no hidden-site leaks through normal views, dry-land exclusions, discovered-site travel, scout/reveal, outcome choices, inability to claim the same site reward twice, returning home and session reset between worlds. The original region/world source and pinned vendor fixtures stay unchanged.

**Next milestone:** if the loop passes actual Godot tests, inspect screenshot interaction and decide on gameplay rules/visuals; then make real location transitions and a versioned save model. Do not mistake a passing Godot smoke test for a finished RPG.
