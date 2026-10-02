# World map and worldbuilding decisions — 2 October 2026

Status: **accepted direction / living roadmap**. This records Mark's decisions for *The Road Has Gone Dark*, not authorization to implement every future feature. Keep this page current whenever we explicitly change direction. The world should feel like dangerous wilderness punctuated by defended islands of civilization and safe roads.

## Current atlas baseline (locked for now)
- GAME-23 mountain illustration and GAME-26 Azgaar vegetation: accepted after visual QA on both `game-11-determinism` and `atlas-showcase-06`. PR #24 merged. Azgaar illustrated relief parameters remain **size 0.85, density 0.36**.
- We are **not** doing small vegetation, mountain, or label polish yet. Each change affects the overall visual hierarchy; evaluate the composition again after roads and settlement symbols are complete.
- Design hierarchy: terrain/biome/relief should read first; important civilization centers next; roads, shipping lanes and incidental infrastructure should be legible but subordinate. Preserve frontier atmosphere.

## Active near-term sequence
1. **GAME-27 — route styling (Done):** Mark approved the thinner, quieter land roads and less prominent sea-lane dots in GAME-11 and showcase screenshots; PR #25 merged (`5f16a7f`). Presentation-only changes, no world-data changes.
2. **GAME-28 — distinct civilization symbols (Done):** Mark selected Game-icons after locally comparing map families. PR #28 merged to `main` on 2 October 2026 (`2a5f63b`). The shared icon provider defaults to selected authored illustrations for burg groups and supported POIs. Original Azgaar map data and terrain remain untouched.
3. **GAME-30 — approved river/UI polish (Done):** PR #29 merged (`4080c4b`). Mark selected quieter blue-green river strokes; the temporary R-key trial and oversized Icon Art Trial panel were removed. No generator, terrain or route modifications.
4. **GAME-31 — macro landmark art and readability (Done, PR #30 merged `ddea66f`):** Mark visually reviewed the deliberately dense ×8 world, landmark decluttering and Map Key; approved the appearance and requested **white icon glyphs and text within the legend** for contrast. PR #30 implements all 36 exact Azgaar landmark types, deterministic screen-aware filtering that protects visible settlement/label bounds, a collapsed 36-entry Map Key with a QA switch, and a legend-only white-ink shader. Godot headless scene interaction, source/attribution coverage and stress-generation checks pass. The **standard world density is unchanged**; gameplay-specific named landmark inspection follows in GAME-22.

## GAME-28: selected art direction (2 October 2026)
- **Decision:** Mark compared the atlas icon options locally in Godot and chose **Game-icons (Delapouite, CC BY 3.0)** as the default settlement and map-POI illustration family on grounds of visual fit and semantic completeness. Do not keep searching or treat other sample scores as the winning decision. Selected art is an illustrated icon system, **not** an overhaul of Azgaar relief or vegetation.
- The first atlas set includes 12 actual sourced role-mapped SVGs (capital, city, town, village, hamlet, fort, monastery, trading, ruins, cave, lighthouse, mine), with attribution to artist Delapouite; 12 is a sample **implementation footprint**, not the full library. The broader [game-icons.net](https://game-icons.net/) catalogue may be curated for GAME-21 local landmarks and future discovery states, rather than mixing period engraving styles indiscriminately.
- Alternative comparison packs (Mercator, de Fer, Müller, Vischer, Ogilby, Hogenburg, Janssonius, Super Rough, Donia) were independently audited and retained in PR #28's historical commit and research notes. CoMiGo and Zatta were excluded after checking actual content. The viewer is development-only; source provenance is documented under `assets/map_icons/trials/`.
- **Implementation:** default `MapIconProvider.family` is `Game-icons`. The obsolete icon-art trial selector was retired. Approved mountains, terrain, vegetation, subdued roads and hidden-site rules remain unchanged.
- **Delivered and accepted:** GAME-28 settlement symbols (PR #28, `2a5f63b`), GAME-30 rivers/UI (PR #29, `4080c4b`), GAME-31 all 36 macro landmark icon types, decluttering and white Map Key (PR #30, `ddea66f`), and GAME-22 clickable landmarks/settlements, safe descriptions and Unicode correction (PR #31, `2e4c960`). No further atlas artwork experiments are planned. Permanent instance-name labels are deliberately deferred: the dense world map uses selected-site inspection, and future player-known labels must respect discoverability.

## World-scale vs regional/local generation: key boundary
Azgaar is the **strategic persistent world-level authority** for geography, climates/biomes, states/provinces, macro-settlements, major roads/rivers, and selected **important macro POIs**. These might be noteworthy ruins, a legendary battlefield, a significant volcano, sacred site, watchtower, unusual dungeon entrance, or other **rare major landmark/story hook**. They should be seeds for narrative/location detail, not all visible quest pins by default. Important: distinguish **objective generated world truth** from **player knowledge/discovery**; hidden locations must remain hidden until learned/discovered.

The local-area/region generator (**GAME-21; Town Forge candidate**) will later build **minor** roads, streams, caves, small ruins, shrines, hamlets, encounters, watchtowers and other discoverable local sites around those stable macro anchors. Local output must respect Azgaar terrain, nearby major settlements and routes, and never duplicate/contradict a world-level POI. Stable parent world IDs and deterministic versioned seeds anchor persistence.

The detailed town generator (**GAME-19; Settlemaker**) expands an Azgaar burg on demand (seed from world seed + stable burg ID, **not the name**), while (**GAME-20; Python DungeonGen**) expands a known/discovered dungeon site on demand using a stable site ID. No town layout, dungeon map or local encounters need to be generated globally. This scale split is deliberate.

Next owners: **GAME-17** first playable world-exploration-loop design (current), then **GAME-7** canonical GameWorld/adapter, **GAME-8/GAME-9** player-facing map and starting-region selection, and **GAME-10** peoples/factions/hidden sites. GAME-22 selection/details are already implemented in the development viewer and approved; future game-facing discovery logic belongs in GAME-10.

## Optional Azgaar systems — decisions
| System | Decision | Intended use |
| --- | --- | --- |
| **Burg groups / classification** | **Selected/implemented (GAME-28)** | Native Azgaar burg categories inform atlas icons and zoom thresholds; downstream settlement-detail generation stays separate. |
| **Markers / points of interest** | **Yes, selectively later (GAME-10/GAME-22)** | Persist major macro-world sites as restrained, possibly undiscovered narrative hooks. Detailed/minor POIs are locally generated later; do not flood map with every marker. |
| **Cultures** | **Experimental only, not committed** | Inspect existing generated data and run a controlled sample before choosing whether to use as source for naming, flavor, factions, settlement context or identity; avoid untested assumptions, cosmetic overhaul or generator tweaks. |
| **Religions / cults** | **Yes, background worldbuilding** | Generate and consume for flavor prose, cults, shrines, conflict/background of the place, NPC dialogue/quests, character/state/settlement info. **Not** necessarily an always-visible map overlay. |
| **Goods, economy, markets, trade** | **Yes, background worldbuilding** | Use if deterministic source data is available and useful for why towns exist, resources, regional professions, caravan stories, scarcity and contextual descriptions; **no** standalone economy simulation/trade UI commitment yet. |
| **Emblems / heraldry** | **Yes, info/detail display later** | Heraldic images or descriptors in faction/state/region/burg information panels; **not** cluttering permanent atlas by default. Check availability and deterministic asset approach first. |
| **Zones, military, battles, geographic feature presentation, trade animation, GIS tooling and other Azgaar features** | **No dedicated implementation planned** | Could inform generated lore/worldbuilding text if readily provided in pinned source; do not treat all upstream features as must-build map layers. Revisit only if gameplay needs justify them. |

## Implementation guardrails
- Azgaar v1.153.1 pinned source; **do not change generator behavior or fixtures casually**. Canonical JSON stays provider-neutral.
- Existing generated records can drive narrative even when no layer is displayed.
- World generation and information revelation are separate concerns. Do not expose hidden major POIs via inspection/UI ahead of player discovery.
- A whole-world burg is **a strategic anchor**, not a pre-generated Settlemaker town. Likewise a global Azgaar marker can imply a future DungeonGen site without constructing that dungeon now.
- Preserve procedural repeatability: stable IDs + namespace/versioned seeds; no seed-specific visual patches.
- Avoid giant SVG/JSON fixture commits for presentation-only work. Review small, scoped PRs in Godot at fitted, medium and close zoom.

## Next handoff
**Current task: GAME-17 (In Progress): design the first playable exploration loop.** GAME-22 was approved and merged as [PR #31](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/31), commit `2e4c960`. Use the proven deterministic world and approved atlas but **do not convert the debug viewer into the final game UI**. Settle player viewpoint, initial party, safe roads versus wilderness, settlement/POI interactions, encounters, game time, knowledge, and minimum save-loop before authoring GAME-7's GameWorld adapter. Follow with GAME-8/9/10; guild roster/survival (GAME-29) and the Town Forge regional map (GAME-21) remain separate backlog design/integration work.

GitHub repository: `marksprietsma-beep/road-has-gone-dark`; Linear project: *The Road Has Gone Dark*.
