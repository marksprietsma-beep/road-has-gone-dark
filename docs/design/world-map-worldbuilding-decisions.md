# World map and worldbuilding decisions — 2 October 2026

Status: **accepted direction / living roadmap**. This records Mark's decisions for *The Road Has Gone Dark*, not authorization to implement every future feature. Keep this page current whenever we explicitly change direction. The world should feel like dangerous wilderness punctuated by defended islands of civilization and safe roads.

## Current atlas baseline (locked for now)
- GAME-23 mountain illustration and GAME-26 Azgaar vegetation: accepted after visual QA on both `game-11-determinism` and `atlas-showcase-06`. PR #24 merged. Azgaar illustrated relief parameters remain **size 0.85, density 0.36**.
- We are **not** doing small vegetation, mountain, or label polish yet. Each change affects the overall visual hierarchy; evaluate the composition again after roads and settlement symbols are complete.
- Design hierarchy: terrain/biome/relief should read first; important civilization centers next; roads, shipping lanes and incidental infrastructure should be legible but subordinate. Preserve frontier atmosphere.

## Active near-term sequence
1. **GAME-27 — route styling (Done):** Mark approved the thinner, quieter land roads and less prominent sea-lane dots in GAME-11 and showcase screenshots; PR #25 merged (`5f16a7f`). Presentation-only changes, no world-data changes.
2. **GAME-28 — Azgaar burg classes & settlement symbol language (now In Progress):** the many **solid dark dots** on zoomed maps are existing small-burg dots drawn by `SettlementMapLayer`. Replace anonymous dots with legible but restrained capitals, major cities, towns, minor burgs, and notable fortified/religious places where **pinned Azgaar v1.153.1 data supports them**. Research available native groups first. No town-detail generation.
3. **After GAME-28:** one holistic atlas readability/polish review, **not** endless isolated tweaking. Mark specifically noted that **rivers are a little too bold/thick at medium/close zoom** (strong dark teal outer stroke and light inner stroke). Keep rivers recognizably blue-green but soften their close-up stroke width/contrast without losing their visibility, after checking against the new settlement symbols. Also reassess terrain vs roads vs towns vs labels vs vegetation together.

## GAME-28: art direction comparison (decision pending)
- Mark rejected first-pass procedural house/castle GDScript silhouettes as too blocky relative to Azgaar mountains and vegetation. Draft PR #27 was closed unmerged.
- **2 October art-screening decision: minimum combined 7/10**, where period-appropriate aesthetic and fantasy/POI breadth each contribute 0–5 (provisional judgement, not objective testing). Exclude from the active selector Kenney 6, Pinhead 6, Osmic 3, and Lucide 3; retain their already merged source files for reproducibility. Keep Game-icons 8, and research additional candidates Mercator 7, de Fer Settlement 8, Donia 7, Zatta 7, CoMiGo 8, Müller 9 and Janssonius 8. More niche fantasy POI sources are documented in GAME-28. See `assets/map_icons/trials/candidate_manifest.json`.
- **Important staging boundary:** Only Game-icons has verified installed artwork out of the passing candidates. Historical/CoMiGo sets are screened and registered as pending, *not* downloaded or available in-game yet; the selector only exposes a candidate once real source-derived capital and town artwork is staged. This avoids false five-way claims, stand-ins and broken X-only options. Procedural remains a baseline, not a scored candidate.
- Use a single style family for both burg symbols and important world-scale POI previews. Same style provider should later support detailed local-region maps in GAME-21. Future global and local maps may have different **scale**, not incompatible art directions; avoid tight provider coupling.
- Mark will judge candidates by **actual Godot visuals on GAME-11 and showcase**, not catalogue screenshots. Avoid silently substituting another pack if a sample fails to render. Preserve original license/attribution notice when distributing.
- Actual world POI information and fog-of-war rules stay with GAME-22/GAME-10; GAME-28's trial is only a visual preview.
- Don't declare an asset winner until Mark chooses based on in-game comparisons.

## World-scale vs regional/local generation: key boundary
Azgaar is the **strategic persistent world-level authority** for geography, climates/biomes, states/provinces, macro-settlements, major roads/rivers, and selected **important macro POIs**. These might be noteworthy ruins, a legendary battlefield, a significant volcano, sacred site, watchtower, unusual dungeon entrance, or other **rare major landmark/story hook**. They should be seeds for narrative/location detail, not all visible quest pins by default. Important: distinguish **objective generated world truth** from **player knowledge/discovery**; hidden locations must remain hidden until learned/discovered.

The local-area/region generator (**GAME-21; Town Forge candidate**) will later build **minor** roads, streams, caves, small ruins, shrines, hamlets, encounters, watchtowers and other discoverable local sites around those stable macro anchors. Local output must respect Azgaar terrain, nearby major settlements and routes, and never duplicate/contradict a world-level POI. Stable parent world IDs and deterministic versioned seeds anchor persistence.

The detailed town generator (**GAME-19; Settlemaker**) expands an Azgaar burg on demand (seed from world seed + stable burg ID, **not the name**), while (**GAME-20; Python DungeonGen**) expands a known/discovered dungeon site on demand using a stable site ID. No town layout, dungeon map or local encounters need to be generated globally. This scale split is deliberate.

Current follow-up owners: **GAME-10** world peoples/factions/hidden sites and objective-vs-discovery state; **GAME-22** known/discovered world marker labels/details/inspection; **GAME-7** canonical GameWorld/adapter; **GAME-8/GAME-9** player-facing layers and start selection. Do not spawn duplicate tickets for these.

## Optional Azgaar systems — decisions
| System | Decision | Intended use |
| --- | --- | --- |
| **Burg groups / classification** | **Yes, next (GAME-28)** | Better civilization symbols, zoom thresholds, info text; later inputs to settlements. Verify pinned v1.153.1 availability instead of assuming newer editor features exist. |
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
Current active issue **GAME-28** after accepted/merged GAME-27. Then assess known/discovered POIs and start-region/world-interaction roadmap (GAME-7, GAME-8, GAME-9, GAME-10, GAME-17, GAME-22), with culture data a separate small experiment **before** we rely on it in game worldbuilding.

GitHub repository: `marksprietsma-beep/road-has-gone-dark`; Linear project: *The Road Has Gone Dark*.
